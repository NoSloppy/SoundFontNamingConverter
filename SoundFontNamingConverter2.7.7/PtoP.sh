#!/bin/sh
	shopt -s extglob
	IFS=$'\n'


	echo " "
	echo "You chose Proffie to Proper Proffie Soundfont renaming/organization."
	echo " "
		echo "Please enter the name of the font folder containting the soundfont files."
		read input
		dirs=$(find "$input" -maxdepth 0 -type d)
		
		echo "Found the following soundfont folder:"
		echo $dirs

	for font in ${dirs[@]}; do
		sounds=$(find "$font" -type f -name '*.wav')
		echo " "
		echo "Sounds to rename/organize:"
		echo "${sounds[*]}"
		otherfiles=$(find -s "$font" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
		echo "Other files to move:"
		echo "${otherfiles[*]}"
		echo " "
		echo "Converting soundfont in $font".

		targetpath="Converted_to_Proper_Proffie"
		mkdir -p "$targetpath/$font"

		if [[ "$font" == *"Extra"* || "$font" == *"extra"* ]]; then
			rsync -rab --no-perms "$font"/ "$targetpath/$font"
			echo "Moving all extras to -> extras folder"
		else
			if [[ "${sounds[*]}" == *"Extra"* || "${sounds[*]}" == *"extra"* ]]; then
				mkdir -p "$targetpath/$font/extras"
				echo "Moving all extras to -> extras folder"
					rsync -rab --no-perms $font/*xtras*/ "$targetpath/$font/extras"
			fi
		fi

		if [[ "$font" == *"Track"* || "$font" == *"track"* ]]; then
			rsync -rab --no-perms "$font"/ "$targetpath/$font"
			echo "Moving all tracks to -> tracks folder"
		else
			if [[ "${sounds[*]}" == *"Track"* || "${sounds[*]}" == *"track"* ]]; then
				mkdir -p "$targetpath/$font/tracks"
				echo "Moving all tracks to -> tracks folder"
				rsync -rab --no-perms "$font/tracks/" "$targetpath/$font/tracks"
			fi
		fi

		for o in $otherfiles; do
			echo "Moving "$o" to -> "$targetpath/$font/${o##*/}
			rsync -ab --no-perms "$o" "$targetpath/$font"
		done

		extracounter=1
		hiddencounter=1
		trackcounter=1
		oldeffect="old"

		for src in ${sounds[@]}; do
			# Move extras folder as-is.
			if [[ $src == *._* ]]; then
				if [[ $hiddencounter = 1 ]]; then
					echo "- Hidden files found and ignored."
					hiddencounter=$((hiddencounter+1))	
				fi
				continue;
			fi
			if [[ $src == *xtra* ]]; then
				if [[ $extracounter = 1 ]]; then
					echo "Already moved extras."
					extracounter=$((extracounter+1))	
				fi
				continue;
			fi
			# Move tracks folder as-is.
			if [[ $src == *rack* ]]; then
				if [[ $trackcounter = 1 ]]; then
					echo "Already moved tracks."
					trackcounter=$((trackcounter+1))	
				fi
				continue;
			fi
			# Strip digits, path, and extension from filename
			effectfile="${src//[0-9]/}"
			effectnopath="${effectfile##*/}"
			effect="${effectnopath%.*}"
			if [ "$effect" == "" ];then
				parentdir="$(dirname "$src")"
				mkdir -p "$targetpath/$font/${parentdir##*/}"
				rsync -ab --no-perms  $src $targetpath/$font/${parentdir##*/}
				echo "Effect is numbers only in subdirectory."
				echo "Moving over as-is : $src -> $targetpath/$font/${parentdir##*/}/${src##*/}"
			else
				# Reset counter for new effect type
				# Post-process NNNN formatted files from last round if needed
				if [[ $effect != $oldeffect ]]; then
					counter=1
					if [ ${#targetfile} -gt 12 ]; then
						echo "Effect exceeds 8 characters, converting to NNNN format"
						renum=0001
						# Convert all sounds from last round to NNNN format
						seq -w 1 9999 | for i in "$subdir/"*.wav
						do
						  read renum
						  mv -v "$i" "$subdir/$renum.wav"
						done
					fi
				fi			
				# Make subfolder for multiples, or leave single in root
				if [ $counter = 2 ]; then
					mkdir -p "$targetpath/$font/$effect"
					subdir=$targetpath/$font/$effect
					# $target is still from previous loop below
					if [ ${#effect} -gt 6 ]; then
						targetfile=$(printf %q "${effect}1.wav")
					else
						targetfile=$(printf %q "${effect}01.wav")
					fi
					rsync -ab --no-perms --remove-source-files "$target" "./$targetpath/$font/$effect/$targetfile"
					echo "Addidional $effect sounds found."
					echo "Moving ${target##*/} into a $effect subfolder and adding first numerical to base name = $targetpath/$font/$effect/$targetfile"
				fi
				# set target filename with correct digit format
				# singular sound
				if [ $counter == 1 ]; then 
					targetfile=$(printf %q "$effect.wav")
				else
					# Check if leading zero is possible, don't exceed 8 chars
					if [ ${#effect} -gt 6 ] || [ $counter -gt 9 ]; then 
						targetfile=$(printf %q "$effect$counter.wav")
					else
						targetfile=$(printf %q "${effect}0$counter.wav")
					fi
				fi
				# 
				if [ $counter -ge 2 ]; then
					target="./$targetpath/$font/$effect/$targetfile"
				else
					target="./$targetpath/$font/$targetfile"
				fi
				if [ $verbosity = "1" ]; then
					echo "Converting source file ${src} to target $target"
				fi
				rsync -ab --no-perms  $src $target
				# increment counter for next effect sound
			fi
			counter=$((counter+1))
			oldeffect="$effect"
		done
				
		echo " "
		echo "Converted soundfont saved in "$targetpath
		echo " "
	done

	echo " "
	echo " "
	echo "Soundfont conversion complete."
	echo " "
	echo " --- MTFBWY ---"
