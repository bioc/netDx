#' Wrapper to create custom input features (patient similarity networks)
#'
#' @param dataList (list) key is datatype (e.g. clinical, rna, etc.,), value is
#'  table or RangedData)
#' Note that unit names should be rownames of the data structure.
#' e.g If dataList$rna contains genes, rownames(dataList) = gene names
#' @param groupList (list) key is datatype; value is a list of unit groupings
#' for that datatype. e.g. If rna data will be grouped by pathways, then 
#' groupList$rna would have pathway names as keys, and member genes as units.
#' Each entry will be converted into a PSN.
#' @param pheno (data.frame) mapping of user-provided patient identifiers (ID)
#' with internally-generated identifiers.
#' @param netDir (char) path to directory where networks will be stored
#' @param filterSet (char) vector of networks to include
#' @param makeNetFunc (function) custom user-function to create PSN. 
#' Must take dataList,groupList,netDir as parameters. Must
#' check if a given groupList is empty (no networks to create) before 
#' the makePSN call for it. This is to avoid trying to make nets for datatypes
#' that did not pass feature selection
#' @param sims (list) Similarity metric settings for patient data. 
#' Keys must be identical to those of groupList. 
#' Values are either of type character, used for built-in similarity functions, 
#' or are functions, when a custom function is provided.
#' @param verbose (logical) print messages
#' @param ... other parameters to makePSN_NamedMatrix() or makePSN_RangedSets()
#' @return (char) vector of network names. Side effect of creating the nets
#' @examples
#'
#'
#' library(curatedTCGAData)
#' library(MultiAssayExperiment)
#' curatedTCGAData(diseaseCode='BRCA', assays='*',dry.run=TRUE,version="1.1.38")
#' 
#' # fetch mrna, mutation data
#' brca <- curatedTCGAData('BRCA',c('mRNAArray'),FALSE,version="1.1.38")
#' 
#' # get subtype info
#' pID <- colData(brca)$patientID
#' pam50 <- colData(brca)$PAM50.mRNA
#' staget <- colData(brca)$pathology_T_stage
#' st2 <- rep(NA,length(staget))
#' st2[which(staget %in% c('t1','t1a','t1b','t1c'))] <- 1
#' st2[which(staget %in% c('t2','t2a','t2b'))] <- 2
#' st2[which(staget %in% c('t3','t3a'))] <- 3
#' st2[which(staget %in% c('t4','t4b','t4d'))] <- 4
#' pam50[which(!pam50 %in% 'Luminal A')] <- 'notLumA'                         
#' pam50[which(pam50 %in% 'Luminal A')] <- 'LumA'
#' colData(brca)$ID <- pID
#' colData(brca)$STAGE <- st2                                                 
#' colData(brca)$STATUS <- pam50
#' 
#' # keep only tumour samples
#' idx <- union(which(pam50 == 'Normal-like'), which(is.na(st2)))
#' cat(sprintf('excluding %i samples\n', length(idx)))
#'                                                                            
#' tokeep <- setdiff(pID, pID[idx])
#' brca <- brca[,tokeep,]
#' 
#' pathList <- readPathways(fetchPathwayDefinitions("October",2020))
#' 
#' brca <- brca[,,1] # keep only clinical and mRNA data
#' 
#' # remove duplicate arrays
#' smp <- sampleMap(brca)
#' samps <- smp[which(smp$assay=='BRCA_mRNAArray-20160128'),]
#' notdup <- samps[which(!duplicated(samps$primary)),'colname']
#' brca[[1]] <- brca[[1]][,notdup]
#' 
#' groupList <- list()
#' groupList[['BRCA_mRNAArray-20160128']] <- pathList[seq_len(3)]
#' makeNets <- function(dataList, groupList, netDir,...) {
#'     netList <- c()
#'     # make RNA nets: group by pathway
#'     if (!is.null(groupList[['BRCA_mRNAArray-20160128']])) {
#'     netList <- makePSN_NamedMatrix(dataList[['BRCA_mRNAArray-20160128']],
#'                 rownames(dataList[['BRCA_mRNAArray-20160128']]),
#'                 groupList[['BRCA_mRNAArray-20160128']],
#'                 netDir,verbose=FALSE,
#'                 writeProfiles=TRUE,...)
#'     netList <- unlist(netList)
#'     cat(sprintf('Made %i RNA pathway nets\n', length(netList)))
#'     }
#' 
#'     cat(sprintf('Total of %i nets\n', length(netList)))
#'     return(netList)
#' }
#' 
#' exprs <- experiments(brca)
#' datList2 <- list()
#' for (k in seq_len(length(exprs))) {
#'  tmp <- exprs[[k]]
#'  df <- sampleMap(brca)[which(sampleMap(brca)$assay==names(exprs)[k]),]
#'  colnames(tmp) <- df$primary[match(df$colname,colnames(tmp))]
#'  tmp <- as.matrix(assays(tmp)[[1]]) # convert to matrix
#'  datList2[[names(exprs)[k]]]<- tmp
#' }
#' pheno <- colData(brca)[,c('ID','STATUS')]
#' netDir <- tempdir()
#' pheno_id <- setupFeatureDB(colData(brca),netDir)
#' createPSN_MultiData(dataList=datList2,groupList=groupList,
#'  pheno=pheno_id,
#'  netDir=netDir,makeNetFunc=makeNets,numCores=1)
#' @export
createPSN_MultiData <- function(dataList, groupList, pheno, netDir=tempdir(), 
		filterSet = NULL, 
    verbose = TRUE, makeNetFunc=NULL, sims=NULL, ...) {
    
    if (missing(dataList)) 
        stop("dataList must be supplied.\n")
    if (missing(groupList)) 
        stop("groupList must be supplied.\n")
 
    # resolve user-provided IDs with internal IDs
    dataList <- lapply(dataList, function(x) {
        midx <- match(colnames(x), pheno$ID)
        colnames(x) <- pheno$INTERNAL_ID[midx]
        x
    })

    if (!is.null(filterSet)) {
        if (length(filterSet) < 1) {
          s1 <- "filterSet is empty."
        	s2 <- "It needs to have at least one net to proceed."
        	stop(paste(s1, s2, sep = " "))
				}
    }

    
    
    # Filter for nets (potentially feature-selected ones)
    if (!is.null(filterSet)) {
        if (verbose) 
            message("\tFilter set provided")
        groupList2 <- list()
        for (nm in names(groupList)) {
            idx <- which(names(groupList[[nm]]) %in% filterSet)
            if (verbose) {
                message(sprintf("\t\t%s: %i of %i nets pass", 
											nm, length(idx), length(groupList[[nm]])))
            }
            if (length(idx) > 0) {
                groupList2[[nm]] <- groupList[[nm]][idx]
            }
        }
        groupList <- groupList2
        sims <- sims[which(names(sims) %in% names(groupList))]
        rm(groupList2)
    }
    
    if (!is.null(makeNetFunc)){
    # call user-defined function for making PSN
        netList <- makeNetFunc(dataList = dataList, groupList = groupList, 
				netDir = netDir, ...)
    } else {
        netList <- createNetFuncFromSimList(dataList=dataList,
            groupList = groupList, 
            netDir = netDir,
            sims = sims, 
            ...
            )
    }
    
    if (length(netList) < 1) 
        stop("\n\nNo features created! Filters may be too stringent.\n")
    
    netID <- data.frame(ID = seq_len(length(netList)), 
				name = netList, ID = seq_len(length(netList)), 
        name2 = netList, 0, 1, stringsAsFactors = TRUE)
    
    # move network files
	fsep=getFileSep()
    prof <- grep(".profile$", netList)
    if (length(prof) > 0) {
        prof <- netList[prof]
        dir.create(paste(netDir,"profiles",sep=fsep))
        for (p in prof) {
            file.rename(from = paste(netDir, p,sep=fsep), 
			to = paste(netDir,"profiles",
				sprintf("1.%i.profile", 
				netID$ID[which(netID$name == p)]),
				sep=fsep))
        }
    }

    dir.create(paste(netDir,"INTERACTIONS",sep=fsep))
    cont <- grep("_cont.txt$", netList)
    if (length(cont) > 0) {
        cont <- netList[cont]
        for (p in cont) {
            file.rename(from = paste(netDir,p,sep=fsep),
		to = paste(netDir,"INTERACTIONS",
			sprintf("1.%i.txt",netID$ID[which(netID$name == p)]),
			sep=fsep))
        }
    }
    
    # write NETWORKS.txt
    write.table(netID, file = paste(netDir,"NETWORKS.txt",sep=fsep), 
	sep = "\t", col.names = FALSE, 
        row.names = FALSE, quote = FALSE)
    
    # write NETWORK_GROUPS.txt
    con <- file(paste(netDir,"NETWORK_GROUPS.txt", sep=fsep), "w")
    write(paste(1, "dummy_group", "geneset_1", "dummy_group", 1, sep = "\t"),
		file = con)
    close(con)
    
    con <- file(paste(netDir,"NETWORK_METADATA.txt",sep=fsep), "w")
    tmp <- paste(netID$ID, "", "", "", "", "", "", "", 
				"", "", 0, "", "", 0, "", 
        "", "", "", "", sep = "\t")
    write.table(tmp, file = con, sep = "\t", col.names = FALSE, 	
				row.names = FALSE, 
        quote = FALSE)
    close(con)
    
    return(netList)
}

