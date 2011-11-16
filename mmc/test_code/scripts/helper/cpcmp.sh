cp $2/$1 $3 
sync
cmp $2/$1 $3/$1
return $?

