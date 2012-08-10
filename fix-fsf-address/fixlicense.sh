#! /bin/bash

FILE="filestofix.mate"

if [ $# -ne 1 ]; then
    echo "Error: no directory argument given\n"
    exit
fi

./fsf.py $1

cd $1

while read line; do
    sed -i "s/\(.*\)59 Temple Place - Suite 330\(.*\)/\151 Franklin St, Fifth Floor\2/" $line
    sed -i "s/\(.*\)59 Temple Place, Suite 330\(.*\)/\151 Franklin St, Fifth Floor\2/" $line
    sed -i "s/\(.*\)675 Mass Ave, Cambridge\(.*\)/\151 Franklin St, Fifth Floor, Boston\2/" $line
    sed -i "s/\(.*\)02111-1307\(.*\)/\102110-1301\2/" $line
    sed -i "s/\(.*\)Boston, MA 02139\(.*\)/\1Boston, MA 02110-1301\2/" $line
    sed -i "s/\(.*\)Cambridge, MA 02139\(.*\)/\1Boston, MA 02110-1301\2/" $line
done < $FILE

rm $FILE
