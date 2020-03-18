#!/bin/bash
echo "Starting the script"
ROOT="12_QFCN_TIMIT_epoch_100_mask"
SOURCE="/home/bio-asp/Documents/data/JND"
DESTINATION="/home/bio-asp/Documents/data/JND44_1k"


echo "Processing noisy wav files"
for j in 0 2 4 6 8 10 12 14 16 18 20 22 23
do
     for k in BabyCry Engine White
     do
	 for l in -6dB -12dB -15dB 0dB 6dB 12dB
	 do
	     for i in $(seq 100)
	     do
		 VAR1="${SOURCE}/${ROOT}_${j}/Noisy/${k}/$l/Test_${i}.wav"
		 VAR2="${DESTINATION}/${ROOT}_${j}/Noisy/${k}/$l/Test_${i}.wav"
		 sox $VAR1 -r 44100 $VAR2
	     done
	 done
     done
done

echo "Processing clean wav files"
for i in $(seq 100)
do
    VAR1="${SOURCE}/Test/Clean/Test_${i}.wav"
    VAR2="${DESTINATION}/Test/Clean/Test_${i}.wav"
    sox $VAR1 -r 44100 $VAR2
done

## echo "Testing using only mask_0"
## for j in 0 
## do
##      for k in BabyCry 
##      do
## 	 for l in -6dB
## 	 do
## 	     for i in $(seq 2)
## 	     do
## 		 VAR1="${SOURCE}/${ROOT}_${j}/Noisy/${k}/$l/Test_${i}.wav"
## 		 VAR2="${DESTINATION}/${ROOT}_${j}/Noisy/${k}/$l/Test_${i}.wav"
## 		 sox $VAR1 -r 44100 $VAR2
## 	     done
## 	 done
##      done
## done

## echo "Removing wav files"

## for j in 0 2 4 6 8 10 12 14 16 18 20 22 23
## do
##     for k in BabyCry Engine White
##      do
## 	 for l in -6dB -12dB -15dB 0dB 6dB 12dB
## 	 do
## 	     for i in $(seq 100)
## 	     do
## 		 VAR2="${DESTINATION}/${ROOT}_${j}/Noisy/${k}/$l/"
## 		 cd $VAR2
## 		 rm Test_$i.wav 
## 	     done
## 	 done
##      done
## done


## echo "Removing wav files in Test/Noisy folder"
## 
##     for k in BabyCry Engine White
##     do
## 	 for l in -6dB -12dB -15dB 0dB 6dB 12dB
## 	 do
## 	     for i in $(seq 100)
## 	     do
## 		 VAR2="${DESTINATION}/Test/Noisy/${k}/$l/"
## 		 cd $VAR2
## 		 rm Test_$i.wav 
## 	     done
## 	 done
##     done

##     echo "Removing wav files in Test/Clean folder"
##     for i in $(seq 100)
##     do
## 	VAR2="${DESTINATION}/Test/Clean/"
## 	cd $VAR2
## 	rm Test_$i.wav
##     done

echo "Existing the script"
