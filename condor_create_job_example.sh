#!/bin/bash

#################################################################################################
# Script to create indvidual condor jobs
#
################################################################################################


# Set variables and paths
DATA=/path/to/data
OUTPUT=/path/to/output
SCRIPTDIR=/path/to/scripts

# Loop over all subjects

for SUBJECT in `cat path/to/subject_list.txt`
do
	
cat > ${SCRIPTDIR}/run_${SUBJECT} << EOF
#!/bin/bash

# Set some variable within script
N_FILES=`wc -l ${DATA}/$SUBJECT`

/pathto/SomeCode.sh \
--indir ${DATA}/${SUBJECT} 
--num_files \$N_FILES
--output $OUTPUT
EOF

done


