function GET_OS_MAJOR_VERS(){

local OS_VENDOR=$1

if [ "$OS_VENDOR" = "redhat" ];
then
        OS_MAJOR_VERS="`cat /etc/redhat-release | head -1 | awk '{ print $7 }' | awk -F. '{ print $1 }'`"
        echo $OS_MAJOR_VERS
        return $TRUE
fi

echo "error"
return $FALSE

}
