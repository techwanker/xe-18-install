echo PWD $PWD     
configure="./configure.properties"
if [ ! -f $configure ] ; then
   echo file $configure does not exist
   exit 1
fi
ls -l
. $configure
set -e
#if [ $UID != 0 ] ; then 
#    echo must be root user >&2
#    exit
#fi
echo USER is $USER    
set -x 
download_path=${zip_file_dir}/${zip_file}
sudo mkdir $install_dir
sudo chown oracle:oinstall $install_dir
sudo cp $download_path $install_dir 
sudo chown oracle:oinstall ${install_dir}/${zip_file}

sudo su oracle -c  ./02-install-apex-18.sh
template_script=03-install-template.sql
run_script=03-install.sql
sed -e "s,&&datafile_name,${datafile_name},"  \
    -e "s,&&tablespace_name,${tablespace_name}," \
    -e "s/&&container/${container}/" \
    $template_script  > $run_script
cat $run_script
export ORACLE_SID=XE
. oraenv
sqlplus / as sysdba @ $run_script
