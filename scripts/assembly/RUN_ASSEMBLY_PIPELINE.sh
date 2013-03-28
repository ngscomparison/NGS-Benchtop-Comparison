#!/bin/bash -e

execDir=$(dirname `readlink -f $0`)

usage () {
    echo -e "\n  Usage: $0 -i <input.fas> -r <ref.fas> -m <tech_mode> [-i <ismin> -I <ismax> -o <outpath> -t <tmp_path>]"
    echo -e "	-i  input: path to sequencing input (.fastq) and if available ancillery file (.xml)"
    echo -e "	-r  ref.fas: path to reference genome fasta file"
    echo -e "	-m  tech_mode: which tech/mode mira should run with (either 454/454_notrace/iontor/iontor_notrace/solexa/solexaPE) "
    echo -e "	-i|-I  ismin/max: is running mira in paired end mode, than this range will be used for indicating insert size range, MANDATORY for solexaPE!"
    echo -e "	-o  outpath: path where the output is stored (default .) "
    echo -e "	-t  tmp_path: base location where the temporary output is stored (default /tmp). Should NOT be a NFS mounted device! "
    exit 1
}

while getopts 'i:o:t:m:r:i:I:h' opt
do
   case $opt in
        i) input=$OPTARG;;
        o) output=$OPTARG;;
        t) tmp_path=$OPTARG;;
        m) mode=$OPTARG;;
        r) ref=$OPTARG;;
        i) ismin=$OPTARG;;
        I) ismax=$OPTARG;;
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

if [[ -z $input ]] || [[ -z $ref ]] || [[ -z $mode ]]; then
    echo -e "\n\tInsufficient parameters\n"
    usage
fi

if [ ! -r ${input} ]; then
    echo -e "Cannot read seqeuncing file: ${input}."
    exit 1
fi

input=`readlink -f ${input}`

if [ -z "${outpath}" ]; then
    outpath=.
    echo -e "No output folder defined, using .\n"
fi

if [ ! -r ${ref} ]; then
    echo -e "Cannot read reference file ${ref}."
    exit 1
fi

if [ -z "${tmp_path}" ]; then
    tmp_path=/tmp
fi
tmp=`mktemp -d -p ${tmp_path}`
if [ ! -d ${tmp} ]; then
    echo -e "Could not create assembly tmp dir in ${tmp_path}. Aborting!\n"
    exit 1;
fi
echo -e "No temp folder defined, using: ${tmp}\n"
echo -e "Free disk space on {$tmp}: `df -h ${tmp}`\n"

if [ -z "${mode}" ]; then
    echo -e "No technology defined. Aborting.\n"
    exit 1;
fi

suffix=`echo "${input}" | awk -F . '{print $NF}'`
prefix=`basename ${input} .${suffix}`
echo "Using: ${prefix} for output folders/files and project identification"
input=`echo ${input} | sed 's/\.fastq$//'`
ref=`readlink -f ${ref}`

####start the assembly 
echo -e "[1] Start assembly\n"
if [ ! -r ${outpath} ]; then
    echo -e "   Creating output base directory: ${outpath}"
    mkdir -p ${outpath}
fi
assDir=`readlink -f ${outpath}`"/${prefix}_assembly"
echo -e "   Creating output directory: ${assDir}"
mkdir -p ${assDir}
cd ${assDir}

settings=""
if [ "${mode}" == "454" ]; then
    ln -s ${input}.xml ${prefix}_traceinfo_in.${mode}.xml
    settings="454_SETTINGS"
elif [ "${mode}" == "454_notrace" ]; then
    mode=454
    settings="-notraceinfo 454_SETTINGS"
elif [ "${mode}" == "iontor" ]; then
    ln -s ${input}.xml ${prefix}_traceinfo_in.${mode}.xml
    settings="IONTOR_SETTINGS"
elif [ "${mode}" == "iontor_notrace" ]; then
    mode=iontor
    settings="-notraceinfo IONTOR_SETTINGS"
elif [ "${mode}" == "solexa" ]; then
    settings="-MI:somrnl=0 SOLEXA_SETTINGS" 
elif [ "${mode}" == "solexaPE" ]; then
    settings="-MI:somrnl=0 SOLEXA_SETTINGS -GE:tismin=${ismin}:tismax=${ismax}"
    mode="solexa"
 
else 
    echo -e "no supporteed technology given, was ${mode}\n"
    exit 1
fi

ln -s ${input}.fastq ${prefix}_in.${mode}.fastq
echo -e "   Executing: mira --project=${prefix} --job=denovo,genome,accurate,${mode} -DI:trt=${tmp} -GE:not=4 ${settings} -ASSEMBLY:mrpc=100 >&${prefix}.log\n"
mira --project=${prefix} --job=denovo,genome,accurate,${mode} -DI:trt=${tmp} -GE:not=4 ${settings} -ASSEMBLY:mrpc=100 >&${prefix}.log
if [ $? -ne 0 ]; then exit $! ; fi
echo -e "   Assembly Complete\n"

echo -e "[2] Removing tmp directory\n"
rm -rf ${tmp}
echo -e "   done. \n"

echo -e "[3] Get result stats\n"
genome_size=`${execDir}/FastaStats.pl -f ${ref} | head -n 1 | awk '{print $2}'`
res=${prefix}_assembly/${prefix}_d_results/${prefix}_out.unpadded.fasta
echo -e "   ${execDir}/assemblathon_stats.pl -csv ${prefix}_assembly/${prefix}_d_results/${prefix}_out.unpadded.fasta \n"
perl ${execDir}/assemblathon_stats.pl -csv ${res} -genome_size ${genome_size}
if [ $? -ne 0 ]; then exit $err ; fi
cd ${assDir}
echo -e "   Summarizing results: perl ${execDir}/summarize_assembly_results.pl ${prefix}\n"
perl ${execDir}/summarize_assembly_results.pl ${prefix}
if [ $? -ne 0 ]; then exit $err ; fi
echo -e "   Written assembly_summary.csv and assembly_errors.csv to ${assDir} \n"
echo -e "\n ASSEMBLY pipeline finished. \n"
