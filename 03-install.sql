set echo on
spool 03-install 
ALTER SESSION SET CONTAINER = xepdb1;
create tablespace apex_data
datafile '/common/xe_database_files/XE/XEPDB1/apex.dbf'  size 256m autoextend on
EXTENT MANAGEMENT LOCAL AUTOALLOCATE SEGMENT SPACE MANAGEMENT AUTO;
exit;

