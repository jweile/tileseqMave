#!/usr/bin/Rscript

# Copyright (C) 2018  Jochen Weile, Roth Lab
#
# This file is part of tileseqMave.
#
# tileseqMave is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# tileseqMave is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with tileseqMave.  If not, see <https://www.gnu.org/licenses/>.

#######################################################################################
# This is script pre-processes count files by translating HGVS strings to protein level
# and calculating relative frequencies from raw counts.
# It takes a single count file as its input so that multiple instances can be run in 
# parallel in an HPC environment.
#######################################################################################

options(stringsAsFactors=FALSE)

#load libraries
library(tileseqMave)
library(argparser)
library(yogilog)
library(hgvsParseR)
library(pbmcapply)

#process command line arguments
p <- arg_parser(
	"Translates HGVS strings in the count files and adds a frequency column.",
	name="translateCounts.R"
)
p <- add_argument(p, "infile", help="count data input file.")
p <- add_argument(p, "paramfile", help="tileseq parameter file.")
p <- add_argument(p, "--outfile", help="output file. Defaults to freqs_sampleN.csv in the same directory.")
p <- add_argument(p, "--logfile", help="log file. Defaults to translateCounts_nn.log in the same directory")
p <- add_argument(p, "--cores", help="number of CPU cores to use",default=4L)
args <- parse_args(p)

countfile <- args$infile
paramFile <- args$paramfile
mc.cores <- args$cores

outfile <- if (is.na(args$outfile)) {
	#if count file follows correct naming pattern, produce corresponding frequency file
	if (grepl("counts_sample\\d+\\.csv",args$infile)) {
		#FIXME: This could cause a problem if the word counts_sample occurs in any directory names
		sub("counts_sample","freqs_sample",args$infile)
	#otherwise, just call it freqs.csv in the same directory
	} else {
		sub("[^/]+$","freqs.csv",args$infile) 
	}
} else args$outfile

logfile <- if (is.na(args$logfile)) {
	if (grepl("counts_sample\\d+\\.csv",args$infile)) {
		sub("csv$","log",sub("counts_sample","translateHGVS_",args$infile))
	} else {
		sub("[^/]+$","translateHGVS.log",args$infile)
	}
} else args$logfile

#set up logger and shunt it into the error handler
logger <- new.logger(logfile)
registerLogErrorHandler(logger)


#Read and validate parameter file
logger$info("Reading parameters")
params <- parseParameters(paramFile)


#read data
counts <- parseCountFile(countfile)

#reconstruct file header
header <- unlist(mapply(
	function(name,value) sprintf("#%s: %s",name,value), 
	name=c("Sample","Tile","Condition","Replicate","Timepoint","Final read-depth"),
	value=sapply(
		c("sample","tile","condition","replicate","timepoint","depth"),
		function(a) attr(counts,a)
	),
	SIMPLIFY=FALSE
))

logger$info("Translating HGVS for",countfile)
#setup HGVS builder
builder <- new.hgvs.builder.p(aacode=3)
#run translation
errors <- 0
transl <- do.call(rbind,lapply(counts$HGVS,function(hgvs) {
	tryCatch({
		translateHGVS(hgvs,params,builder)
	},error=function(e) {
		logger$warn("Error processing string: ",hgvs,"\n")
		# stop(e)
		errors <<- errors+1
	})
}))
if (errors > 0) {
	stop("Errors occurred during translation. Terminating process.")
}
#add result columns
logger$info("Calculating frequencies for",countfile)
counts$HGVS_pro <- transl[,1]
counts$frequency <- counts$count/attr(counts,"depth")
counts <- counts[,c("HGVS","HGVS_pro","count","frequency")]


logger$info("Saving to file",outfile)
#overwrite count file with results
con <- file(outfile,open="w")
writeLines(header,con)
write.csv(counts,con,row.names=FALSE,quote=FALSE)
close(con)


logger$info("Done")
