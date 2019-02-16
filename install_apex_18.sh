echo PWD $PWD     
configure="./configure.properties"
if [ ! -f $configure ] ; then
   echo file $configure does not exist
   exit 1
fi
set -e  # terminate on error

export ORACLE_SID=XE
. oraenv


check_sys_uid() {\
   echo SYS_UID $SYS_UID
   if [ -z $SYS_UID ] ; then
      echo "SYS_UID must be exported" 
      exit 1
   fi
   user_name=$(echo $SYS_UID | cut -d "/" -f 1  | tr [:upper:] [:lower:])
   echo user_name $user_name
   if [ $user_name != sys ] ; then
      echo user_name is $user_name but must be sys
      exit 1
   fi

   service_name=$(echo $SYS_UID | cut -d @ -f 2 )
   if [ -z $service_name ] ; then
        echo no service name specified, can not find "@"
        exit 1
   fi
   #service_name=$(echo $SYS_UID | cut -d @ -f 2| tr [:upper:] [:lower:])
   #echo service_name $service_name
   #if [ -z $service_name ] ; then
      #echo service_name not specified $service_name
      #exit 1
   #fi
  
}


install_apex() {
    echo USER is $USER    
    set -x 
    download_path=${apex_zip_file_dir}/${zip_file}
    install_apex() {
    sudo mkdir $apex_install_dir
    sudo chown oracle:oinstall $apex_install_dir
    sudo cp $download_path $apex_install_dir 
    sudo chown oracle:oinstall ${apex_install_dir}/${apex_zip_file}
    
    sudo su oracle -c  ./02-install-apex-18.sh
    local template_script=03-install-template.sql
    local run_script=03-install.sql
    sed -e "s,&&apex_datafile_name,${apex_datafile_name},"  \
        -e "s,&&apex_tablespace_name,${apex_tablespace_name}," \
        -e "s/&&container/${container}/" \
        $template_script  > $run_script
    cat $run_script
    sqlplus / as sysdba @ $run_script
}

check_sys_uid() 
