#!/bin/bash

FILE=$1 #takes in the input from the filename
MaxNode=0

IFS=$'\n' #split on 'lines'
ARRAY_OF_LOOPS=($(grep '^L' "$FILE"))

#C style for loop
for (( i = 0; i < ${#ARRAY_OF_LOOPS[@]}; i++))
do
    LINE="${ARRAY_OF_LOOPS[$i]}"
    #echo "Got line ${LINE}"

    if [[ "$LINE" =~ [L],([0-9,\s]+) ]] #rematch with memory
    then
	#echo "HERE! Got a loop ${BASH_REMATCH[1]}"
	IFS=',' read -ra NODES <<< "${BASH_REMATCH[1]}"
	ARRAY_OF_LOOPS[$i]="" #empty this out to replace it
	for (( j = 1; j < ${#NODES[@]}; j++ ))
	do
	    ARRAY_OF_LOOPS[$i]+="   ${NODES[(($j-1))]},${NODES[$j]}"
	done
	#echo "NODES[0] is ${NODES[0]}"
	ARRAY_OF_LOOPS[$i]+="   ${NODES[-1]},${NODES[0]}"
    else
	#default: print an error
	echo "Could not parse this line: ${LINE}"
	#echo "Expecting line of the form: (V|R),int,int,int OR L,int,int,int,..."
	exit 1
    fi
done

declare -A IDX
index=0

for EDGE in "${EDGES[@]}"
do
    read A B R <<< "$EDGE"
    IDX["I_${A}${B}"]=$index
    ((index++))
done

NUM_EDGES=$index

declare -A EQN
declare -a EDGES

while read LINE
do
    #echo "Here is the whole line: $LINE"
    case $LINE in

	[VR],[0-9]*,[0-9]*,[0-9]* )
	    if [[ "$LINE" =~ ([VR]),([0-9]*),([0-9]*),([0-9]*) ]] #rematch with memory
	    then #populate an array of equations EQN[]

		TYPE=${BASH_REMATCH[1]}
        	N1=${BASH_REMATCH[2]}
		N2=${BASH_REMATCH[3]}
		VAL=${BASH_REMATCH[4]}
	        
		if [ "$TYPE" = R ]
		then
		    EQN["$N1"]+="-1 i_${N1}${N2}   " #negative direction
		    EQN["$N2"]+=" 1 i_${N1}${N2}   " #positive direction
		    EDGES+=("$N1 $N2 $VAL")
		fi
		

		for (( i = 0; i < ${#ARRAY_OF_LOOPS[@]}; i++ ))
		do
		    
		    LOOP_LINE="${ARRAY_OF_LOOPS[$i]}"
		    NEW_LINE=""
                    #A='echo \$LINE | sed s/3/!!!/'
		    #echo "HERE: $A"

		    for EDGE in $LOOP_LINE
		    do
			if [[ "$EDGE" == "$N1,$N2" ]]
			then
			    NEW_LINE+="   +${VAL}i_${N1}${N2}"
			elif [[ "$EDGE" == "$N2,$N1" ]]
			then
			    NEW_LINE+="   -${VAL}i_${N1}${N2}"
			else
			    NEW_LINE+="   $EDGE"
			fi
		    done
		    
		    ARRAY_OF_LOOPS[$i]="$NEW_LINE"
		done
		
		#Tracking MaxNode
		(( N1 > MaxNode )) && MaxNode=$N1
		(( N2 > MaxNode )) && MaxNode=$N2
	    fi
	    ;;

	"#"* )
	    ;;
	L,* )
	    ;;
	* )
	    echo "Could not parse this line: $LINE"
	    exit 1
	    ;;
    esac
done < "$FILE"

echo "    NODE EQUATIONS    "
for EQUATION in $(seq 1 $MaxNode)
do
    echo "EQN[$EQUATION] = ${EQN[$EQUATION]}"
done

echo "    LOOP EQUATIONS    "
for LOOP in "${ARRAY_OF_LOOPS[@]}"
do
    echo "$LOOP = 0"
done

> edges.txt

for EDGE in "${EDGES[@]}"
do
    echo "$EDGE" | awk '{print $1, $2}' >> edges.txt
done

> matrix.txt
> b.txt

for EQUATION in $(seq 1 $MaxNode)
do
    ROW=""
    for ((i=0;i<NUM_EDGES;i++))
    do
	ROW+="0 "
    done

    for term in ${EQN[$EQUATION]}
    do
	sign=${term:0:1}
	var=${term:2}

	idx=${IDX[$var]}

	if [[ $sign == "-" ]]; then
	    ROW_ARRAY=($ROW)
	    ROW_ARRAY[$idx]=-1
	    ROW="${ROW_ARRAY[*]}"
	else
	    ROW_ARRAY=($ROW)
	    ROW_ARRAY[$idx]=1
	    ROW="${ROW_ARRAY[*]}"
	fi
    done

    echo "$ROW" >> matrix.txt
    echo "0" >> b.txt
done

for LOOP in "${ARRAY_OF_LOOPS[@]}"
do
    ROW=""

    for ((i=0;i<NUM_EDGES;i++))
    do
	ROW+="0 "
    done

    echo "$ROW" >> matrix.txt
    echo "0" >> b.txt
done

ROW=""
for ((i=0;i<NUM_EDGES;i++))
do
    ROW+="0 "
done

read A B R <<< "${EDGES[0]}"
ROW_ARRAY=($ROW)
ROW_ARRAY[0]=1
ROW="${ROW_ARRAY[*]}"

echo "$ROW" >> matrix.txt
echo "$R" >> b.txt
