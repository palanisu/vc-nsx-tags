#!/usr/bin/env bash
_vc_csv_file=$1
_nsx_csv_file=$2

while IFS="," read -r _compName _uuid _envi _tags ; do
echo $_compName $_uuid $_envi $_tags
_guest_info=$(grep -w "${_uuid}" "${_nsx_csv_file}")
if [ -n "${_guest_info}" ]; then
    GUEST_INFO="SUCCESS"
    GUEST_NAME="${_compName}"
    GUEST_UUID="${_uuid}"
    echo "${GUEST_NAME}" "${GUEST_UUID}"
    if [ ${GUEST_INFO} = SUCCESS ]; then
        _envi_info=$(grep -w "${_envi}" "${_guest_info}")
            if [ -n "${_envi_info}" ];  then
                ENVI_INFO="SUCCESS"
                ENVI_NAME="${_envi}"
		        echo $ENVI_NAME
            else
                ENVI_INFO="FAIL"
            fi
        _tags_info=$(grep -w "${_tags}" "${_guest_info}")
            if [ -n "${_tags_info}" ]; then
                #_tags_items=$(echo $_tags | tr -d '[:blank:]' | sed -e 's/,/ /g' -e 's/^"//' -e 's/"$//' )
                _tags_items=$(echo $_tags | tr -d '[:blank:]')
                IFS=', ' read -r -a tag_item <<< "$_tags_items"
                for i in "${!tag_item[@]}"; do
                    _tag[i]="${tag_item[$i]}"
                    echo "${_tag[@]}"
                    
                done

            else
                echo "No Tags"
            fi
    else
        echo "No VM Info"
    fi

else
    echo "VM not IN list"

fi
    
done <"$_vc_csv_file"
 
