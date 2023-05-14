echo "Please enter the path to download and extract the data to: "
read dl_extract_to

declare -A url_dict # holding links to data
declare -A vol_dict # bookkeeping size of data

# mono-temporal data
echo "Also downloading SEN12MS-CR data set."
mkdir -p $dl_extract_to'/SEN12MSCR'

url_dict['mono_s2_winter']='https://dataserv.ub.tum.de/s/m1554803/download?path=/&files=ROIs2017_winter_s2.tar.gz'
vol_dict['mono_s2_winter']='30580552'

url_dict['mono_s2_cloudy_winter']='https://dataserv.ub.tum.de/s/m1554803/download?path=/&files=ROIs2017_winter_s2_cloudy.tar.gz'
vol_dict['mono_s2_cloudy_winter']='30580812'

# S1 data of SEN12MS-CR
echo "Also downloading associated S1 data."

url_dict['mono_s1_winter']='https://dataserv.ub.tum.de/s/m1554803/download?path=/&files=ROIs2017_winter_s1.tar.gz'
vol_dict['mono_s1_winter']='9460956'

# req=0
# # integrate file size across archives
# for key in "${!vol_dict[@]}"; do
# 	# for each archive: sum up
# 	curr=${vol_dict[$key]}
# 	req=$((req+curr))
# done

# echo
# echo
# # df -h $dl_extract_to
# avail=$(df $dl_extract_to | awk 'NR==2 { print $4 }')
# if (( avail < req )); then
# 	echo "Not enough space (512-byte disk sectors) on path "$dl_extract_to". Available "$avail". Required "$req #>&2
# 	exit 1
# else
# 	echo "Consuming "$req" of "$avail" (512-byte disk sectors) on path "$dl_extract_to
# fi
# echo
# echo

# download each archive individually, then extract individually

# fetch the actual data
for key in "${!url_dict[@]}"; do
    url=${url_dict[$key]}
    filename=$(basename "$url")
    filename=${filename:7}
    # download
    wget --no-check-certificate -c -O $dl_extract_to'/'$filename ${url_dict[$key]}
    # unzip and delete archive
    tar --extract --file $dl_extract_to'/'$filename -C $dl_extract_to
    rm $dl_extract_to'/'$filename
done

# move the extracted data to its respective place (this may take a while, because we use rsync rather than mv)
echo "Moving data in place, please don't stop this process."
for key in "${!url_dict[@]}"; do
    url=${url_dict[$key]}
    filename=$(basename "$url")
    filename=${filename:7:-7} # remove base URL and trailing *.tar.gz
    if [[ ${url_dict[$key]} == *"m1554803"* ]]; then
    	# move to SEN12MSCR directory
	  	mv $dl_extract_to'/'$filename $dl_extract_to'/SEN12MSCR'
  	elif [[ ${url_dict[$key]} == *"m1639953"* ]]; then
		# move train ROI to SEN12MSCRTS directory
		no_prefix_filename=${filename:3}
		rsync -a -remove-source-files $dl_extract_to'/'$no_prefix_filename/* $dl_extract_to'/SEN12MSCRTS' 2>/dev/null
		rm -rf $dl_extract_to'/'$no_prefix_filename
	else
		# move test ROI to SEN12MSCRTS directory
		rsync -a -remove-source-files $dl_extract_to'/'$filename/* $dl_extract_to'/SEN12MSCRTS'
		rm -rf $dl_extract_to'/'$filename
	fi
done

echo
echo "Completed downloading, extracting and moving data! Enjoy :)"