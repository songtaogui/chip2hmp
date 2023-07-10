
# >>>>>>>>>>>>>>>>>>>>>>>> Common functions >>>>>>>>>>>>>>>>>>>>>>>>
gst_log () {
    local info=$1
    if [[ "$quiet" != "TRUE" ]];then
        echo -e "\033[36m[$(date +'%y-%m-%d %H:%M')]\033[0m $info" >&2
    fi
}

gst_rcd () {
    local info=$1
    if [[ "$verbose" == "TRUE" ]];then
        echo -e "\033[32m>>>------------>\033[0m $info" >&2
    fi
}

gst_err () {
    local info=$1
    echo -e "\033[31m\033[7m[ERROR]\033[0m --> $info" >&2
}

gst_warn () {
    local info=$1
    if [[ "$quiet" != "TRUE" ]];then
        echo -e "\033[35m[WARNING]\033[0m --> $info" >&2
    fi
}

gstcat () {
    # if file is bz2 compreesed, call bzip2 -dcfq, else call gzip -dcfq
    local files=$@
    local fp=""
    for fp in ${files[@]}
    do
        local info=$(file $fp)
        if [[ "${info}" == *"symbolic link"* ]];then
            fp=$(readlink $fp)
            info=$(file $fp)
        fi
        if [[ "${info}" == *"bzip2 compressed"* ]];then
            bzip2 -dcfq $fp
        else
            gzip -dcfq $fp
        fi
    done
}
export -f gstcat

check_files_executable(){
    local num_related_file=1
    local related_file=""
    for related_file in  "$@"
    do
        if [[ ! -x "$related_file" ]]; then
            echo -e "\033[31m\033[7m[ERROR]\033[0m --> NOT EXECUTABLE: $related_file " >&2
            let num_related_file++
        fi
    done
    if [ "$num_related_file" -ne 1 ];then
        if [ "${-#*i}" == "${-}" ];then
            exit 1
        else
            return 1
        fi
    fi
}

check_files_exists(){
    local num_related_file=1
    local related_file=""
    for related_file in  "$@"
    do
        if [[ ! -s "$related_file" ]]; then
            echo -e "\033[31m\033[7m[ERROR]\033[0m --> No file: $related_file " >&2
            let num_related_file++
        fi
    done
    if [ "$num_related_file" -ne 1 ];then
        if [ "${-#*i}" == "${-}" ];then
            exit 1
        else
            return 1
        fi
    fi
}

check_abs_path() {
    local var_cc=1
    local check_file=""
    for check_file in "$@";do
        if [[ "${check_file:0:1}" != "/" ]]; then
            echo -e "\033[31m\033[7m[ERROR]\033[0m --> $check_file was not an ABSOLUTE path." >&2
            let var_cc++
        fi
    done
    if [ "$var_cc" -ne 1 ];then
        if [ "${-#*i}" == "${-}" ];then
            exit 1
        else
            return 1
        fi
    fi
}

check_R_lib() {
    local num_R_lib=1
    local tp_R_lib=""
    Rscript --vanilla --slave -e '
        argv=as.character(commandArgs(TRUE));
        check = argv %in% rownames(installed.packages())
        if (all(check)) {
            quit(save="no", status=0)
        } else {
            write(paste0("\033[31m\033[7m[ERROR]\033[0m --> Not installed: ", paste0(argv[!check], collapse=", ")), stderr())
            quit(save="no", status=1)
        }
    ' $*
    if [ $? -ne 0 ];then
        if [ "${-#*i}" == "${-}" ];then
            exit 1
        else
            return 1
        fi
    fi
}

check_sftw_path(){
    local num_tp_program=1
    local tp_program=""
    for tp_program in "$@"
    do
        if ! which $tp_program >/dev/null 2>&1 ; then
            echo -e "\033[31m\033[7m[ERROR]\033[0m --> Program not in PATH: $tp_program " >&2
            let num_tp_program++
        fi
    done
    if [ "$num_tp_program" -ne 1 ];then
        if [ "${-#*i}" == "${-}" ];then
            exit 1
        else
            return 1
        fi
    fi
}

# usage: $0 var regex
test_string_regex () {
    local var=$1
    local regex=$2
    echo "$var" | grep -P "$regex" 1>/dev/null 2>&1
}
export -f test_string_regex

# usage: $0 var_name regex errmsg
check_var_regex () {
    local var_name=$1
    local regex=$2
    local errmsg=$3
    local var=$(eval echo "$"$var_name)
    echo "$var" | grep -P "$regex" 1>/dev/null 2>&1
    if [ $? -ne 0 ];then
        echo -e "\033[31m\033[7m[ERROR]\033[0m --> Wrong $var_name value: ${var}! $errmsg" >&2
        if [ "${-#*i}" == "${-}" ];then
            exit 1
        else
            return 1
        fi
    fi
}
export -f check_var_regex


check_var_empty () {
    local var_cc=1
    local var_name=""
    local var=""
    for var_name in "$@"; do
        var=$(eval echo "$"$var_name)
        case ${var} in
            '')
                echo -e "\033[31m\033[7m[ERROR]\033[0m --> $var_name is empty: '$var' " >&2
                let var_cc++ ;;
            *) ;;
        esac >&2
    done
    if [ "$var_cc" -ne 1 ];then
        if [ "${-#*i}" == "${-}" ];then
            exit 1
        else
            return 1
        fi
    fi
}

check_var_numeric () {
    local var_cc=1
    local var_name=""
    local var=""
    local vartag="NA"
    for var_name in "$@"; do
        var=$(eval echo "$"$var_name)
        vartag=$(
            perl -se '
                BEGIN{use Scalar::Util qw(looks_like_number);$t="YES";}
                $t="NO" unless looks_like_number($var);
                print $t' -- -var=$var
            )
        if [[ $vartag != "YES" ]];then
            echo -e "\033[31m\033[7m[ERROR]\033[0m --> The value of Var \$$var_name is not a number: '$var' " >&2
            let var_cc++
        fi
    done
    if [ "$var_cc" -ne 1 ];then
        if [ "${-#*i}" == "${-}" ];then
            exit 1
        else
            return 1
        fi
    fi
}

check_suffix () {
    check_suffix_file=$( basename $1 )
    check_suffix=$2
    # add x incase file has no suffix
    if [[ "${check_suffix_file##*.}"x != "$check_suffix"x ]];then
        echo "[ERROR] --> $check_suffix_file should have suffix: '$check_suffix'." >&2
        if [ "${-#*i}" == "${-}" ];then
            exit 1
        else
            return 1
        fi
    fi
}


trim()
{
    # <doc:trim>
    #
    # Removes all leading/trailing whitespace
    #
    # Usage examples:
    #     echo "  foo  bar baz " | trim  #==> "foo  bar baz"
    #
    # </doc:trim>

    ltrim "$1" | rtrim "$1"
}

squeeze()
{
    # <doc:squeeze>
    #
    # Removes leading/trailing whitespace and condenses all other consecutive
    # whitespace into a single space.
    #
    # Usage examples:
    #     echo "  foo  bar   baz  " | squeeze  #==> "foo bar baz"
    #
    # </doc:squeeze>

    local char=${1:-[[:space:]]}
    sed "s%\(${char//%/\\%}\)\+%\1%g" | trim "$char"
}

abspath()
{
    # <doc:abspath>
    #
    # Gets the absolute path of the given path.
    # Will resolve paths that contain '.' and '..'.
    # Think readlink without the symlink resolution.
    #
    # Usage: abspath [PATH]
    #
    # </doc:abspath>

    local path=${1:-$PWD}

    # Path looks like: ~user/...
    # Gods of bash, forgive me for using eval
    if [[ $path =~ ~[a-zA-Z] ]]; then
        if [[ ${path%%/*} =~ ^~[[:alpha:]_][[:alnum:]_]*$ ]]; then
            path=$(eval echo $path)
        fi
    fi

    # Path looks like: ~/...
    [[ $path == ~* ]] && path=${path/\~/$HOME}

    # Path is not absolute
    [[ $path != /* ]] && path=$PWD/$path

    path=$(squeeze "/" <<<"$path")

    local elms=()
    local elm
    local OIFS=$IFS; IFS="/"
    for elm in $path; do
        IFS=$OIFS
        [[ $elm == . ]] && continue
        if [[ $elm == .. ]]; then
            elms=("${elms[@]:0:$((${#elms[@]}-1))}")
        else
            elms=("${elms[@]}" "$elm")
        fi
    done
    IFS="/"
    echo "/${elms[*]}"
    IFS=$OIFS
}

ensure() {
    if ! "$@"; then
        gst_err "command failed: $*";
        if [ "${-#*i}" == "${-}" ];then
            exit 1
        else
            return 1
        fi
    fi
}

version_ge(){
	# $0 query_version required_version
	# version greater or equal
	local query=$1
	local ref=$2
	check_var_regex "query" "^(v\d)|^(\d)" "should be version numbers, start 'v' is tolerant"
	check_var_regex "ref" "^(v\d)|^(\d)" "should be version numbers, start 'v' is tolerant"
	local err=$3
	if ! printf '%s\n%s\n' "$ref" "$query" | sort --check=quiet --version-sort; then
		gst_err "$3: need $ref or above"
		if [ "${-#*i}" == "${-}" ];then
			exit 1
		else
			return 1
		fi
	fi
}

export -f ensure check_R_lib gst_log gst_rcd gst_warn gst_err \
          check_files_executable check_var_empty check_var_numeric \
          check_sftw_path check_suffix check_files_exists check_abs_path \
          squeeze abspath

