echo PWD $PWD     
configure="./configure.properties"
. $configure
    echo USER is $USER    
    #set -x 
if [ ! -f $configure ] ; then
   echo file $configure does not exist
   exit 1
fi
set -e  # terminate on error


export ORACLE_SID=XE
. oraenv

apex_version=$(basename $apex_zip_file .zip)
echo apex_install_dir $apex_install_dir
apex_admin_dir=${apex_install_dir}/${apex_version}/apex
echo apex_admin_dir $apex_admin_dir 
ords_version=$(basename $ords_zip_file .zip)
echo ords_version $ords_version
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
    download_path=${apex_zip_file_dir}/${zip_file}
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

change_apex_pwd() {
    check_sys_uid
    echo "apex_admin_dir $apex_admin_dir"
    if [ ! -d $apex_admin_dir ];  then
        echo apex_admin_dir $apex_admin_dir does not exist
        exit 1
    fi;
    set  -e    
    cd $apex_admin_dir    
    echo PWD $(pwd) 
    sqlplus $SYS_UID as sysdba @ apxchpwd.sql
}

unlock_apex() {
    check_sys_uid
    echo "apex_admin_dir $apex_admin_dir"
    if [ ! -d $apex_admin_dir ];  then
        echo apex_admin_dir $apex_admin_dir does not exist
        exit 1
    fi;

    if [ -z $APEX_PASSWORD ] ; then
        echo APEX_PASSWORD must be exported
        exit 1
    fi
    set  -e    
    cd $apex_admin_dir    
    echo PWD $(pwd) 
    sqlplus $SYS_UID as sysdba <<!EOF!
set echo on
ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK;
ALTER USER APEX_PUBLIC_USER IDENTIFIED BY $APEX_PASSWORD;
create profile APEX_USER_PROFILE limit PASSWORD_LIFE_TIME UNLIMITED;
alter user APEX_PUBLIC_USER profile APEX_USER_PROFILE;
exit;
!EOF!
}

install_ords() {
   echo "*****"
   echo "install_ords"
   echo "*****"
   echo ords_zip_file $ords_zip_file
   local ords_install_path=$zip_file_dir/$ords_zip_file
   if [ -z $ords_zip_file ] ; then
       echo check property ords_zip_file in configure.properties
       exit 1
   fi
   if [ ! -f $ords_install_path ] ; then 
       echo install file $ords_install_path  does not exist check configure.properties
       echo zip_file_dir is $zip_file_dir 
       exit 1
   fi
   set -x 
   sudo cp $ords_install_path $apex_install_dir
   sudo chown oracle:oinstall $apex_install_dir/$ords_zip_file
   sudo su - oracle -c "cd $apex_install_dir && unzip -d $ords_version $ords_zip_file"
   apex_images_dir=$apex_admin_dir/images
   target_dir=$apex_install_dir/$ords_version
   if [ ! -d $apex_images_dir ] ; then 
       echo images dir $apex_images_dir does not exist
       exit 1
   fi
   if [ ! -d $target_dir ] ; then 
       echo images dir $target_dir does not exist
       exit 1
   fi
   sudo cp -lr $apex_images_dir $target_dir
}

create_ords_data() { 
    if [ -z $ords_data_file ] ; then
        echo ords_data_file not in configure.properties
        exit 1
    fi;
    sqlplus $SYS_UID as sysdba <<!EOF!
set echo on 
CREATE TABLESPACE ORDS_DATA
datafile $ords_data_file SIZE 256m autoextend on
EXTENT MANAGEMENT LOCAL AUTOALLOCATE SEGMENT SPACE MANAGEMENT AUTO;
exit;
!EOF!
}

apex_rest_config() {
    cd $apex_admin_dir
    pwd
    sqlplus $SYS_UID as sysdba @ apex_rest_config
}


create_response_file() {
   set -x -e
   cat response.template | cut -f 1 -d "#" | sed -e "s/\^apex_password\^/$APEX_PASSWORD/" -e "s,\^apex_install_dir\^,$apex_install_dir," -e "s,\^xe_listener_port\^,$xe_listener_port,"  > response.text
   cat response.text
   cp response.text $apex_install_dir/$ords_version
}

install_ords() {
   
   cd $apex_install_dir/$ords_version
   java -jar ords.war install advanced < response.text
}

echo "************************"
echo "* install_apex          "
echo "* change_apex_pwd       "
echo "************************"

change_apex_pwd
#unlock_apex
#install_ords
#create_ords_data
#create_response_file
#install_ords
#apex_rest_config
