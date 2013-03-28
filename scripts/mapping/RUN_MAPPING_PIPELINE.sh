#!/bin/bash

# This script executes all mapping steps consecutive, according to nick lomans pipeline (with modifications)
# with some modifications and additions

#the path to all related scripts and executables
execDir=$(dirname `readlink -f $0`)
Rcmd="R --vanilla -q --slave"

usage () {
    echo -e "\n  Usage: $0 -i <input.fas> -r <ref.fas> [ -o <outpath> -p <prefix>]"
    echo -e "-i  input.fas: path to sequencing output file (multiple fasta)"
    echo -e "-r  ref.fas: path to reference genome fasta file"
    echo -e "-o  outpath: path where the output is stored (default .) "
    echo -e "-p  prefix: if given this prefix will be used for all output data [default=input]"
    exit 1
}

while getopts 'i:o:r:p:h' opt
do
   case $opt in
        i) input=$OPTARG;;
        o) outpath=$OPTARG;;
        r) ref=$OPTARG;;
        p) prefix=$OPTARG;;
        h) usage;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

if [[ -z $input ]] || [[ -z $ref ]]; then
    usage
fi

refStrain=`basename ${ref}`
refStrain=`echo -e ${refStrain} | sed 's/\.fasta$//'` #just in case
input=`readlink -f ${input}`

if [ ! -r ${input} ]; then
    echo -e "Cannot read seqeuncing file: ${input}."
    exit 1
fi

if [ ! -r ${ref} ]; then
    echo -e "Cannot read reference file ${ref}."
    exit 1
fi

if [ -z "${outpath}" ]; then
    outpath=.
    echo -e "No output folder defined, using: ./"
fi

if [ -z "${prefix}" ]; then
    suffix=`echo "${input}" | awk -F . '{print $NF}'`
    prefix=`basename ${input} .${suffix}`
    echo -e "No prefix specified, using: ${prefix}"
fi

if [ ! -r ${outpath}/${prefix}_mapping ]; then
    echo -e "Creating output base directory"
    mkdir -p ${outpath}/${prefix}_mapping
fi

outpath=${outpath}/${prefix}_mapping


####start the mapping
#first link the reference and reads into the outdir for easier processing
cwd=`echo $PWD`
refAbs=`readlink -f ${ref}`
inAbs=`readlink -f ${input}`
cd ${outpath}
ln -s ${refAbs} REFERENCE
ln -s ${inAbs} INPUT
cd ${cwd}
mapOut=${outpath}/${prefix}
echo -e "\n[1]Start mapping\n"
echo -e "   ${execDir}/gobwa.sh ${mapOut} ${input} ${ref} \n"
${execDir}/gobwa.sh ${mapOut} ${input} ${ref} 
if [ $? -ne 0 ]; then exit $err ; fi
echo -e "\n   Mapping completed\n"
prefixUni=${prefix}.uni
mapOutUni=${mapOut}.uni

####create the index file for read_bam.py
aliTXTUni=${outpath}/${prefixUni}.alignment.txt
echo -e "[2]Creating alignment index file ${aliTXTUni} \n"
echo -e "#Name\tPath\tDescription\tAssemblySoftware\tReference\n${prefixUni}\t${mapOutUni}.sorted.bam\tmapping\tBWASW\t${refStrain}\n" > ${aliTXTUni} 
if [ $? -ne 0 ]; then exit $err ; fi
echo -e "   done.\n"

#####read bam and summarizes the indels/subs 
aliTABUni=${outpath}/${prefixUni}.alignment.tab
echo -e "[3]Creating alignemnt based error summary file (tsv table) ${aliTABUni} \n"
echo -e "   ${execDir}/read_bam.py ${aliTXTUni} ${ref} > ${aliTABUni}\n" 
${execDir}/read_bam.py ${aliTXTUni} ${ref} > ${aliTABUni} 
if [ $? -ne 0 ]; then exit $err ; fi
echo -e "   done.\n"

#### create indel summary table
if [ $? -ne 0 ]; then exit $err ; fi
indelTABUni=${aliTABUni}.res
echo -e "[4]Creating R error summary Table ${aliTABUni}.res \n"
echo -e "   cat ${execDir}/indel_summary_table.R | ${Rcmd} --args ${aliTABUni}\n"  
cat ${execDir}/indel_summary_table.R | ${Rcmd} --args ${aliTABUni}  
if [ $? -ne 0 ]; then exit $err ; fi
echo -e "   done.\n"

##### calculate the alignment accuracy
outACCUni=${outpath}/${prefixUni}.acc
echo -e "[5]Creating alignemnt based per read accuracy ${outACCUni} \n"
echo -e "   ${execDir}/calculate_accuracy.py ${mapOutUni}.sorted.bam ${ref} > ${outACCUni}\n"  
${execDir}/calculate_accuracy.py ${mapOutUni}.sorted.bam ${ref} > ${outACCUni}  
if [ $? -ne 0 ]; then exit $err ; fi
echo -e "   done.\n"

##### calculate the coverage
outCOVUni=${outpath}/${prefixUni}.sorted.cov
echo -e "[6] Creating per base consensus coverage ${outCOVUni}.ungapped \n"
${execDir}/calc_coverage.sh ${mapOutUni}.sorted.bam    
if [ $? -ne 0 ]; then exit $err ; fi
echo -e "   perl ${execDir}/CountMeanCov.pl ${outCOVUni}.ungapped > ${outpath}/${prefixUni}.meanCovs\n" 
perl ${execDir}/CountMeanCov.pl ${outCOVUni}.ungapped > ${outpath}/${prefixUni}.meanCovs 
if [ $? -ne 0 ]; then exit $err ; fi
echo -e "   done.\n"

### summarize the mapping results
echo -e "[7] Summarizing mapping results"
echo -e "   ${execDir}/summarize_mapping_results.pl ${outpath}\n"
${execDir}/summarize_mapping_results.pl ${outpath}
echo -e "   done.\n"
echo -e "\n MAPPING pipeline finished.\n"
