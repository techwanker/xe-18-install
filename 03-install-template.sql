set echo on
spool 03-install 
ALTER SESSION SET CONTAINER = &&container;
create tablespace &&tablespace_name
datafile '&&datafile_name'  size 256m autoextend on
EXTENT MANAGEMENT LOCAL AUTOALLOCATE SEGMENT SPACE MANAGEMENT AUTO;
exit;

