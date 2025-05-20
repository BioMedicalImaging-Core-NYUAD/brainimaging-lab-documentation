#!/bin/bash -l
#SBATCH --job-name=create_labels
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=32G
#SBATCH --time=10:00:00  # Adjust the time limit as needed
#SBATCH --output=/scratch/hz3752/MRI/fingertapping/createlabels_%A_%a.out
#SBATCH --error=/scratch/hz3752/MRI/fingertapping/createlabels_%A_%a.err
#SBATCH --array=0  # Adjust this to match the number of subjects minus one

# JK & IB 28/10/2022

# From https://github.com/WinawerLab/atlasmgz
# example to run sh createAtlasLabels.sh wlsubj121 /Volumes/server/Projects/Retinotopy_NYU_3T
#export SUBJID=${1}
SUBJID="0665"
#export WORK_DIR=${2} # e.g /CBI/Users/jankurzawski/data/Retinotopy_NYU_3T
USER=hz3752
PROJECT_NAME=fingertapping

#TODO: Set this
WORK_DIR=/scratch/$USER/MRI/$PROJECT_NAME

export SUBJECTS_DIR=${WORK_DIR}/derivatives/freesurfer
export LABEL_DIR=${SUBJECTS_DIR}/sub-${SUBJID}/label


module load freesurfer
git clone https://github.com/hzaatiti/atlasmgz.git $SUBJECTS_DIR/fsaverage/atlasmgz
git pull $SUBJECTS_DIR/fsaverage/atlasmgz
export DO_IMPORT_WANG=1 # Only need to run once, to bring atlas into fsaverage space
export DO_IMPORT_GLASSER=1 # Only need to run once, to bring atlas into fsaverage space

export DO_IMPORT_NATIVESPACE=1
export DO_CONVERT_ATLAS=1

export DO_IMPORT_BENSON=1

# Load wang2015.mgz and a colorLUT to extract labels in fsaverage space. Convert all labels into an annotation file
if [ "$DO_IMPORT_WANG" == 1 ]; then

roinamesWang=("" "V1v" "V1d" "V2v" "V2d" "V3v" "V3d" "hV4" "VO1" "VO2" "PHC1" "PHC2" "TO2" "TO1" "LO2" "LO1" "V3B" "V3A" "IPS0" "IPS1" "IPS2" "IPS3" "IPS4" "IPS5" "SPL1" "FEF")

mkdir -p ${SUBJECTS_DIR}/fsaverage/label/Wang2015
for hemi in lh rh; do 

	for i in {1..25}; do  
		mri_cor2label --i ${SUBJECTS_DIR}/fsaverage/atlasmgz/${hemi}.wang15_mplbl.v1_0.mgz --id ${i} \
		--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.${roinamesWang[${i}]}.label \
		--surf fsaverage $hemi inflated;
	done; 

	mris_label2annot --s fsaverage --h ${hemi} --ctab ${SUBJECTS_DIR}/fsaverage/atlasmgz/Wang2015_ColorLUT.txt --a Wang2015 \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.V1v.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.V1d.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.V2v.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.V2d.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.V3v.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.V3d.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.hV4.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.VO1.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.VO2.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.PHC1.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.PHC2.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.TO2.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.TO1.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.LO2.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.LO1.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.V3B.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.V3A.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.IPS0.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.IPS1.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.IPS2.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.IPS3.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.IPS4.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.IPS5.label  \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.SPL1.label \
	--l ${SUBJECTS_DIR}/fsaverage/label/Wang2015/${hemi}.Wang2015.FEF.label
done

fi


# Load glasser2016.mgz and a colorLUT to extract labels in fsaverage space. Convert all labels into an annotation file
if [ "$DO_IMPORT_GLASSER" == 1 ]; then

mkdir -p ${SUBJECTS_DIR}/fsaverage/label/Glasser2016

for hemi in lh rh; do 
	unset labelString

	for i in {1..180}; do  
		mri_cor2label --i ${SUBJECTS_DIR}/fsaverage/atlasmgz/${hemi}.glasser16_atlas.v1_0.mgz --id ${i} \
		--l ${SUBJECTS_DIR}/fsaverage/label/Glasser2016/${hemi}.Glasser2016.${i}.label \
		--surf fsaverage $hemi inflated;

  		fileString="--l ${SUBJECTS_DIR}/fsaverage/label/Glasser2016/${hemi}.Glasser2016.${i}.label "
		labelString="${labelString}${fileString}"
	done; 

	mris_label2annot --s fsaverage --h ${hemi} --ctab ${SUBJECTS_DIR}/fsaverage/atlasmgz/Glasser2016_ColorLUT.txt --a Glasser2016 \
	${labelString}
done

fi

if [ "$DO_IMPORT_BENSON" == 1 ]; then

	mkdir ${SUBJECTS_DIR}/sub-${SUBJID}/surf/benson14
	export PARAMS=("benson14_varea.v4_0" "benson14_eccen.v4_0" "benson14_angle.v4_0" "benson14_sigma.v4_0") 

	for P in "${PARAMS[@]}"

	do

		mri_surf2surf --srcsubject fsaverage --trgsubject sub-$SUBJID --hemi rh --sval ${SUBJECTS_DIR}/fsaverage/atlasmgz/rh.${P}.mgz --tval ${SUBJECTS_DIR}/sub-${SUBJID}/surf/benson14/rh.${P}.mgz
		mri_surf2surf --srcsubject fsaverage --trgsubject sub-$SUBJID --hemi lh --sval ${SUBJECTS_DIR}/fsaverage/atlasmgz/lh.${P}.mgz --tval ${SUBJECTS_DIR}/sub-${SUBJID}/surf/benson14/lh.${P}.mgz

	done

fi



if [ "$DO_IMPORT_NATIVESPACE" == 1 ]; then

	# Transform annotation file with Wang2015 atlas ROIs into labels in indv subject space
	mri_surf2surf --srcsubject fsaverage --trgsubject sub-$SUBJID --hemi rh --sval-annot $SUBJECTS_DIR/fsaverage/label/rh.Wang2015 --tval $SUBJECTS_DIR/sub-${SUBJID}/label/rh.Wang2015.annot
	mri_surf2surf --srcsubject fsaverage --trgsubject sub-$SUBJID --hemi lh --sval-annot $SUBJECTS_DIR/fsaverage/label/lh.Wang2015 --tval $SUBJECTS_DIR/sub-${SUBJID}/label/lh.Wang2015.annot

	mkdir -p $SUBJECTS_DIR/sub-${SUBJID}/label/Wang2015

	mri_annotation2label --subject sub-$SUBJID --hemi rh --annotation Wang2015 --outdir ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015
	mri_annotation2label --subject sub-$SUBJID --hemi lh --annotation Wang2015 --outdir ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015

	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V1v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V1d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V1.label
	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V1v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V1d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V1.label

	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V2v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V2d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V2.label
	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V2v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V2d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V2.label

	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V3v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V3d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V3.label
	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V3v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V3d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V3.label

	# Transform annotation file with Glasser2016 atlas ROIs into labels in indv subject space
	mri_surf2surf --srcsubject fsaverage --trgsubject sub-$SUBJID --hemi rh --sval-annot $SUBJECTS_DIR/fsaverage/label/rh.Glasser2016 --tval $SUBJECTS_DIR/sub-${SUBJID}/label/rh.Glasser2016.annot
	mri_surf2surf --srcsubject fsaverage --trgsubject sub-$SUBJID --hemi lh --sval-annot $SUBJECTS_DIR/fsaverage/label/lh.Glasser2016 --tval $SUBJECTS_DIR/sub-${SUBJID}/label/lh.Glasser2016.annot

	mkdir -p $SUBJECTS_DIR/sub-${SUBJID}/label/Glasser2016

	mri_annotation2label --subject sub-$SUBJID --hemi rh --annotation Glasser2016 --outdir ${SUBJECTS_DIR}/sub-${SUBJID}/label/Glasser2016
	mri_annotation2label --subject sub-$SUBJID --hemi lh --annotation Glasser2016 --outdir ${SUBJECTS_DIR}/sub-${SUBJID}/label/Glasser2016

fi


