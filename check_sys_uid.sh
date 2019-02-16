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

check_sys_uid
