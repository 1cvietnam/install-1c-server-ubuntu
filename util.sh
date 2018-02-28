#Echo delimiter
function delimiter() {
	echo -e "\n---------------------------\n"
}

# Echo message
function message() {
	delimiter
	echo $1
	delimiter
}