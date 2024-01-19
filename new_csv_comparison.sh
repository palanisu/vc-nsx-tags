#!/usr/bin/env bash
_vc_csv_file=$1
_nsx_csv_file=$2
_vc_nsx_report=$3

echo -e "GUEST_NAME,GUEST_UUID,ENVIRONMENT,VC_TAG_STATUS,NSX_TAG_STATUS" > "${_vc_nsx_report}"

while IFS="," read -r _compName _uuid _envi _tags ; do
declare -A _tag=()
declare -A ntags=()
_guest_info=$(grep -w "${_uuid}" "${_nsx_csv_file}")
if [ -n "${_guest_info}" ]; then
    GUEST_INFO="SUCCESS"
    GUEST_NAME="${_compName}"
    GUEST_UUID="${_uuid}"
    if [ ${GUEST_INFO} = SUCCESS ]; then
        ENVI_NAME=""
        if [[ -n  "${_envi//\"}" ]]; then
            ENVI_NAME="${_envi//\"}"
            _envi_info=$(grep "${ENVI_NAME}" <<< "${_guest_info}")
                if [ -n "${_envi_info}" ];  then
                    ENVI_INFO="SUCCESS"
                    ENVI_NAME="${_envi//\"}"
                else
                    ENVI_INFO="FAIL"
                    EN_NAME=$(echo "${_guest_info}" | awk -F "," '{ print $3 }')
                    NEW_EN_NAME=${EN_NAME//\"}
                fi
        else
            ENVI_INFO="NC"
            EN_NAME=$(echo "${_guest_info}" | awk -F "," '{ print $3 }')
            NEW_EN_NAME=${EN_NAME//\"}
        fi

        _tags_items=$(echo $_tags | tr -d '[:blank:]' | sed -e 's/,/ /g' -e 's/^"//' -e 's/"$//' )
        if [[ -n "${_tags_items}" ]]; then
            TAG_INFO="SUCCESS"
                                
            IFS=', ' read -r -a tag_item <<< "$_tags_items"
            for i in "${!tag_item[@]}"; do
                if grep -q "${tag_item[$i]}" <<< "${_guest_info}" ; then
                _tag["${tag_item[$i]}"]="vc-nsx-Matching"
                else
                _tag["${tag_item[$i]}"]="vc-nsx-NotMatching"
                fi

            done
        else
            TAG_INFO="FAIL"
        fi

        NTAG_ITEMS=$(echo "${_guest_info}" | awk -F "\"," '{ print $4 }' | tr -d '[:blank:]'  | sed -e 's/,/ /g' -e 's/^"//' -e 's/"$//')
        if [[ -n "${NTAG_ITEMS}" ]]; then
            NTAG_INFO="SUCCESS"

            IFS=', ' read -r -a NTAG_ITEM <<< "$NTAG_ITEMS"
            for ntag in "${!NTAG_ITEM[@]}"; do
                if grep -q "${NTAG_ITEM[$ntag]}" <<< "${_tags_items}" ; then
                ntags["${NTAG_ITEM[$ntag]}"]="nsx-vc-Matching"
                else
                ntags["${NTAG_ITEM[$ntag]}"]="nsx-vc-NotMatching"
                fi

            done
        else
            NTAG_INFO="FAIL"
        fi
else
    echo "No VM Info"
fi
else
    GUEST_INFO="FAIL"
fi
# echo -n "${GUEST_NAME}","${GUEST_UUID}",
    if [[ -n "${ENVI_NAME}" ]]; then
        if [[ "${ENVI_INFO}" = "SUCCESS" ]]; then
            ENVI_RESULT="${ENVI_NAME} = Matching"
            # echo -n \""${ENVI_RESULT}"\",
        elif [[ "${ENVI_INFO}" = "FAIL" ]]; then
            if [[ -n "${NEW_EN_NAME}" ]]; then
                ENVI_RESULT="VC = ${ENVI_NAME}, NSX = ${NEW_EN_NAME}"
                # echo -n \""${ENVI_RESULT}"\",
            else
                ENVI_RESULT="VC = ${ENVI_NAME}, NSX = NotConfigured"
                # echo -n \""${ENVI_RESULT}"\",
            fi
        fi
    else
        if [[ -n "${NEW_EN_NAME}" ]]; then 
            ENVI_RESULT="VC = NotConfigured, NSX = ${NEW_EN_NAME}"
            # echo -n \""${ENVI_RESULT}"\",
        else
            ENVI_RESULT="VC = NotConfigured, NSX = NotConfigured"
            # echo -n \""${ENVI_RESULT}"\",
        fi
    fi
if [[ "${TAG_INFO}" == "SUCCESS" ]]; then
    for i in "${_tag[@]}"; do 
        if [[ "vc-nsx-Matching" != $i ]]; then 
            TAG_ST=True 
            break
        else 
            TAG_ST=False 
        fi
    done
    if [[ "${TAG_ST}" == "False" ]]; then 
        TAG_RESULT="All VCTags Matching,"
        # echo -n \""${TAG_RESULT}"\",
    else
        TAG_RESULT=""
        # echo -n "\""
        for i in "${!_tag[@]}"; do
            TAG_RESULT="${i} = ${_tag[$i]}", "${TAG_RESULT}"
        done
        # echo -n "${TAG_RESULT%?}"
        # echo -n "\","
    fi
else
TAG_RESULT="No VCTags Configured"
# echo -n \""${TAG_RESULT}"\",
fi

if [[ "${NTAG_INFO}" == "SUCCESS" ]]; then
    for i in "${ntags[@]}"; do 
        if [[ "nsx-vc-Matching" != $i ]]; then 
            NTAG_ST=True 
            break
        else 
            NTAG_ST=False 
        fi
    done
    if [[ "${NTAG_ST}" == "False" ]]; then 
        NTAG_RESULT="All NSXTags Matching,"
        # echo -n \""${NTAG_RESULT}"\",
    else
        NTAG_RESULT=""
        # echo -n "\""
        for i in "${!ntags[@]}"; do
            NTAG_RESULT="${i} = ${ntags[$i]}", "${NTAG_RESULT}"
        done
        # echo -n "${NTAG_RESULT%?}"
        # echo -n "\""
    fi
else
NTAG_RESULT="No VCTags Configured"
# echo -n \""${NTAG_RESULT}"\",
fi

echo -e "${GUEST_NAME}","${GUEST_UUID}",\""${ENVI_RESULT}"\",\""${TAG_RESULT%?}"\",\""${NTAG_RESULT%?}"\" >> "${_vc_nsx_report}"
#echo ""
done <"$_vc_csv_file"
