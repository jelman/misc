#!/bin/bash
#

Usage() {
cat << EOF

    Usage: vol_slicer <bg_img> [OPTIONS]

    OPTIONS:
            -x -y -z            specify set of slices to save as image (e.g. -z "2 4 6 8 10")
                                numbers > 1 specify slicenumbers, numbers < 1 specify proportions.
            -cog, -max          determines location of Center of gravity or voxel with maximum value
                                as voxel coordinate, will override specifications for each voxel location
            -set                set of proportional slice numbers that are used for all three dimensions.
                                this option is only effective when -x/y/z are not specified.
            -stat <flnm>        statistical map
            -trans              transparent colors
            -pxl                number of pixels seperating two images (default:10)
            -thick              increase width of slice line
            -neg                render also the negative stat map
            -noside             do not show right side label
            -nomm               print slice distance from center voxel
            -cx                 for single voxel display overlay slice selections on stat maps
            -s <sclfctr>        scaling factor
            -bgint <min max>    intensity range for the background image
            -statrng <min max>  scaling theshold
            -out  <outname>     filename for output data
            -keep               do not delete temporary files


            ###########################################################
            ##   (c) wolf zinke (2008) - part of the MaFIA toolbox   ##
            ##       for comments and questions: <a href="/cgi-bin/webadmin?LOGON=A3%3Dind1212%26L%3DFSL%26E%3D7bit%26P%3D3966390%26B%3D--------------060804050309080009070204%26T%3Dtext%252Fplain%3B%2520charset%3DUTF-8%3B%2520name%3D%2522vol_slicer%2522%26N%3Dvol_slicer%26attachment%3Dq" target="_parent" >[log in to unmask]</a>   ##
            ###########################################################

EOF
    exit 1
}

# ToDo" Get Rid Of xstr/ystr/zstr ...

#----------------------------------------------------------------------#
if [ $# -lt 1 ]; then
    Usage
else
    bg_img=`remove_ext $1`;
    shift
fi

text2png(){
    if [ $# -lt 3 ]
    then
        ptsz=14
    else
        ptsz=$3
    fi
    echo "$1" | convert -font Palatino-Bold -background black -pointsize $ptsz -fill LightYellow -trim text:- $2
}


#----------------------------------------------------------------------#
outnm="${bg_img}_sliceselection.png"
bgint=`fslstats $bg_img -r`
smint="3 10"

scl=1
pxl=10
sdlbl=""
trans=0
do_keep=0
do_neg=0
do_thick=0
tmpdir=`tmpnam tmpPSC`
xstr=""
ystr=""
zstr=""
slcwdth=1
statmap=""
getsmint=1
doMM=1
doCX=0
SglVXL=1
def_set="0.2 0.3 0.4 0.5 0.6 0.7 0.8"
get_coord=0
usedefset=1
ovly_stat=0

rm $tmpdir

#----------------------------------------------------------------------#
# get options
while [ $# -gt 0 ] ;
do
    case $1 in
       -out)    outnm=$2
                shift 2
                ;;
       -stat)   statmap=`remove_ext $2`
                ovly_stat=1
                shift 2
                ;;
        -x)     xstr="$1 '$2'"
                xslc="$2"
                usedefset=0
                shift 2
                ;;
        -y)     ystr="$1 '$2'"
                yslc="$2"
                usedefset=0
                shift 2
                ;;
        -z)     zstr="$1 '$2'"
                zslc="$2"
                usedefset=0
                shift 2
                ;;
      -set)     def_set=$2
                shift 2
                ;;
      -max)     get_coord=1
                coorstr="-x"
                usedefset=0
                shift
                ;;
      -cog)     get_coord=1
                coorstr="-C"
                usedefset=0
                shift
                ;;
        -s)     scl=$2
                shift 2
                ;;
       -nomm)   doMM=0
                shift
                ;;
       -cx)     doCX=1
                shift
                ;;
       -bgint)  bgint="$2 $3"
                shift 3
                ;;
     -statrng)  smint="$2 $3"
                getsmint=0
                shift 3
                ;;
      -thick)   do_thick=1
                slcwdth=3
                shift
                ;;
      -trans)   trans=1
                shift
                ;;
     -noside)   sdlbl="-u"
                shift
                ;;
       -neg)    do_neg=1
                shift
                ;;
       -pxl)    pxl=$2
                shift 2
                ;;
       -keep)   do_keep=1
                shift
                ;;
          -*)   echo "Wrong option: <$1>"
                echo ""
                Usage
                ;;
           *)   break
                ;;
    esac
done

#----------------------------------------------------------------------#
# determine voxel location of CoG or Max
if [ $get_coord -eq 1 ]
then
    if [ $ovly_stat -eq 1 ]
    then
        coords=`fslstats $statmap $coorstr`
    echo "fslstats $statmap $coorstr"
    else
        coords=`fslstats $bg_img $coorstr`
    echo "fslstats $bg_img $coorstr"
    fi

    X=`echo $coords | awk '{print $1}'| xargs printf "%1.0f"`
    Y=`echo $coords | awk '{print $2}'| xargs printf "%1.0f"`
    Z=`echo $coords | awk '{print $3}'| xargs printf "%1.0f"`
    echo "slice coordinates: X:$X Y:$Y Z:$Z"

    if [ $(echo "$X+$Y+$Z" | bc -l) -eq 0 ]
    then
        echo "WARNING: Not data available to determine CoG or Max!"
        xslc="0.5"
        yslc="0.5"
        zslc="0.5"
        xstr="0.5"
        ystr="0.5"
        zstr="0.5"
    else
        xstr="-x '$X'"
        xslc="$X"
        ystr="-y '$Y'"
        yslc="$Y"
        zstr="-z '$Z'"
        zslc="$Z"
    fi
fi

mkdir $tmpdir;

slcfl=`echo $outnm | sed -e 's/.png/.slc/g'`
echo  "bgimg: $bg_img" > $slcfl
slcsc=`echo "$scl / 2" | bc -l`

if [ $(($doCX+$do_neg)) -eq 2 ]
then
    echo "WARNING: Can not do crosshair overlay if -neg option is used!"
    doCX=0
fi

#----------------------------------------------------------------------#
Xsz=`fslval $bg_img dim1`
Ysz=`fslval $bg_img dim2`
Zsz=`fslval $bg_img dim3`

numX=0
numY=0
numZ=0

# if no slices are specified, use the default set of relative slices
# if [ "Z$xstr$ystr$zstr" == 'Z' ]

if [ $usedefset -eq 1 ]
then
    xslc=""
    yslc=""
    zslc=""

    for cslc in $def_set
    do
        cxn=`echo "$Xsz * $cslc" | bc -l | xargs printf "%1.0f"`
        xslc="$xslc $cxn"

        cyn=`echo "$Ysz * $cslc" | bc -l | xargs printf "%1.0f"`
        yslc="$yslc $cyn"

        czn=`echo "$Zsz * $cslc" | bc -l | xargs printf "%1.0f"`
        zslc="$zslc $czn"
    done

    xstr="-x '$xslc'"
    ystr="-y '$yslc'"
    zstr="-z '$zslc'"
fi

#----------------------------------------------------------------------#
# test whether just a single voxel is specified and
# if proportional slices are specified determine corresponding slice number
# x
if [ "$xstr" ]
then
    nslc=""
    for cslc in $xslc
    do
        if [ $(echo "$cslc < 1" | bc -l) -eq 1 ]
        then
            cnslc=$(echo "$Xsz * $cslc" | bc -l | xargs printf "%1.0f" )
            nslc="$nslc$cnslc "
        else
            nslc="$nslc$cslc " # strange things happen when the space is put elsewhere
        fi
        numX=$(($numX+1))
    done
    xslc=$nslc
    xstr="-x '$xslc'"
fi

if [ ! $numX -eq 1 ]
then
    SglVXL=0
fi

# y
if [ "$ystr" ]
then
    nslc=""
    for cslc in $yslc
    do
        if [ $(echo "$cslc < 1" | bc -l) -eq 1 ]
        then
            cnslc=$(echo "$Ysz * $cslc" | bc -l | xargs printf "%1.0f" )
            nslc="$nslc$cnslc "
        else
            nslc="$nslc$cslc " # strange things happen when the space is put elsewhere
        fi
        numY=$(($numY+1))
    done
    yslc=$nslc
    ystr="-y '$yslc'"
fi

if [ ! $numY -eq 1 ]
then
    SglVXL=0
fi

# z
if [ "$zstr" ]
then
    nslc=""
    for cslc in $zslc
    do
        if [ $(echo "$cslc < 1" | bc -l) -eq 1 ]
        then
            cnslc=$(echo "$Zsz * $cslc" | bc -l | xargs printf "%1.0f" )
            nslc="$nslc$cnslc "
        else
            nslc="$nslc$cslc " # strange things happen when the space is put elsewhere
        fi
        numZ=$(($numZ+1))
    done
    zslc=$nslc
    zstr="-z '$zslc'"
fi

if [ ! $numZ -eq 1 ]
then
    SglVXL=0
fi

#----------------------------------------------------------------------#
# get the slice representation
fslmaths $bg_img -mul 0 -add 1 $tmpdir/all_slices -odt char

png_str=""
set_cnt=0

if [ $SglVXL -eq 1 ]
then
    fslmaths $bg_img -mul 0 -add 1 $tmpdir/allone -odt char

    if [ $do_thick -eq 1 ]
    then
        cX=$(($xslc-1))
        cY=$(($yslc-1))
        cZ=$(($zslc-1))
    else
        cX=$xslc
        cY=$yslc
        cZ=$zslc
    fi

    fslmaths $tmpdir/all_slices -roi 0   $Xsz     $cY $slcwdth $cZ $slcwdth 0 1 $tmpdir/xslcsel
    fslmaths $tmpdir/all_slices -roi $cX $slcwdth 0   $Ysz     $cZ $slcwdth 0 1 $tmpdir/yslcsel
    fslmaths $tmpdir/all_slices -roi $cX $slcwdth $cY $slcwdth 0   $Zsz     0 1 $tmpdir/zslcsel

    fslmaths $tmpdir/xslcsel -add $tmpdir/yslcsel -add $tmpdir/zslcsel $tmpdir/slcsel
    overlay 0 1 $bg_img $bgint $tmpdir/slcsel 1 4 $tmpdir/slc_vol

    slicer $tmpdir/slc_vol -s $slcsc $sdlbl -x -$xslc $tmpdir/selX.png -y -$yslc $tmpdir/selY.png -z -$zslc $tmpdir/selZ.png

    convert $tmpdir/selX.png -trim $tmpdir/selX.png
    convert $tmpdir/selY.png -trim $tmpdir/selY.png
    convert $tmpdir/selZ.png -trim $tmpdir/selZ.png
fi

#----------------------------------------------------------------------#
# prepare overlay image
if [ $ovly_stat -eq 1 ]
then
    if [ $getsmint -eq 1 ]
    then
        if [ $do_neg -eq 1 ]
        then
            smint=`fslstats $statmap -a   -r`
        else
            smint=`fslstats $statmap -l 0 -r`
        fi
    fi

    rngmin=$(echo "$smint" | cut -d' ' -f1)
    rngmax=$(echo "$smint" | cut -d' ' -f2)
    rngdiff=$(echo "$rngmax>$rngmin" | bc -l)

    if [ $rngdiff -eq 0 ]
    then
        imcp $bg_img $tmpdir/curr_img
    else
        statstr=""
        cnt=0
        for cstat in $statmap
        do
            cnt=$(($cnt+1))
            statstr="$statstr $cstat $smint"
        done

    #echo "$statstr"
        if [ $do_neg -eq 1 ]
        then
            if [ $cnt -gt 1 ]
            then
                echo ""
                echo "WARNING: negative map could only be used with one statistical map as input"
                echo ""
            else
                fslmaths $statmap -mul -1 $tmpdir/negmap
                statstr="$statstr $tmpdir/negmap $smint"
            fi
        fi

        if [  $(($doCX+$cnt)) -gt 2 ]
        then
            echo "WARNING: Can not do crosshair overlay if more stat maps are used!"
            doCX=0
        fi

        if [ $doCX -eq 1 ]
        then
            overlay $trans 0 $bg_img $bgint $statstr $tmpdir/slcsel 1 4 $tmpdir/curr_img
        else
            overlay $trans 0 $bg_img $bgint $statstr $tmpdir/curr_img
        fi
    fi
    echo  "statmap:   $statmap" >> $slcfl
    echo  "statrange: $smint  " >> $slcfl
else
    imcp $bg_img $tmpdir/curr_img
fi
#----------------------------------------------------------------------#
# X
if [ $numX -gt 0 ]
then
    origMM=`fslhd $bg_img | grep sto_xyz:1 | awk ' { if($5>=0) { print $5} else {print $5*-1 }}'`
    vxlres=`fslval $bg_img pixdim1`
    origVXL=` echo "$origMM / $vxlres" | bc -l | awk ' { printf  "%.0f\n", $0 } '`

    xstr="X slices [mm]:"

#    xslices=""
    if [ $SglVXL -eq 0 ]
    then
        fslmaths $tmpdir/all_slices -mul 0 $tmpdir/xslcsel -odt char
    fi

    cnt=0
    for cslc in $xslc
    do
        if [ $cslc -gt $Xsz ]
        then
            echo ""
            echo "ERROR: Selected slice <$cslc> exceed number of slices in X dimension"
            echo ""
            rm -r $tmpdir
            exit
        fi

        slicer $tmpdir/curr_img -s $scl -u -x -$cslc $tmpdir/X_${cslc}.png

        cvxlMM=`echo "($origVXL - $cslc) * $vxlres" | bc -l | awk ' { printf  "%6.2f\n", $0 } ' `
        mmX=$cvxlMM
        xstr=`echo "$xstr  $cvxlMM;"`

        if [ $doMM -eq 1 ]
        then
            montage -geometry +0+0 -font Palatino-Bold -background black  -fill LightYellow -pointsize 12 -label "$cvxlMM mm"   $tmpdir/X_${cslc}.png $tmpdir/X_${cslc}.png
        fi

        cnt=$(($cnt+1))
        if [ $cnt -eq 1 ]
        then
            cp $tmpdir/X_${cslc}.png $tmpdir/Xset.png
        else
            pngappend $tmpdir/Xset.png + $pxl $tmpdir/X_${cslc}.png $tmpdir/Xset.png
        fi

        if [ $do_thick -eq 1 ]
        then
            cslc=$(($cslc-1))
        fi

        if [ $SglVXL -eq 0 ]
        then
            fslmaths $tmpdir/all_slices -roi $cslc $slcwdth 0 $Ysz 0 $Zsz 0 1 $tmpdir/tmp_slcsel
            fslmaths $tmpdir/xslcsel -add $tmpdir/tmp_slcsel $tmpdir/xslcsel
        fi
    done

    echo "$xstr"
    echo "$xstr" >> $slcfl

    if [ $SglVXL -eq 0 ]
    then
        overlay 0 1 $bg_img $bgint $tmpdir/xslcsel 1 4 $tmpdir/Xslc_vol

        slicer   $tmpdir/Xslc_vol -s $slcsc $sdlbl -y 0.5   $tmpdir/XselY.png -z 0.5 $tmpdir/XselZ.png
        pngappend $tmpdir/XselY.png - 0   $tmpdir/XselZ.png $tmpdir/Xsel.png
        pngappend $tmpdir/Xsel.png + $pxl $tmpdir/Xset.png  $tmpdir/Xset.png
    fi

    png_str="$png_str $tmpdir/Xset.png"
    set_cnt=$(($set_cnt+1))
fi

# Y
if [ $numY -gt 0 ]
then
    origMM=`fslhd $bg_img | grep sto_xyz:2 | awk ' { if($5>=0) { print $5} else {print $5*-1 }}'`
    vxlres=`fslval $bg_img pixdim2`
    origVXL=` echo "$origMM / $vxlres" | bc -l | awk ' { printf  "%.0f\n", $0 } '`

    ystr="Y slices [mm]:"

#    yslices=""
    if [ $SglVXL -eq 0 ]
    then
        fslmaths $tmpdir/all_slices -mul 0 $tmpdir/yslcsel -odt char
    fi

    cnt=0
    for cslc in $yslc
    do
        if [ $cslc -gt $Ysz ]
        then
            echo ""
            echo "ERROR: Selected slice <$cslc> exceed number of slices in Y dimension"
            echo ""
            rm -r $tmpdir
            exit
        fi

        slicer $tmpdir/curr_img -s $scl -u -y -$cslc $tmpdir/Y_${cslc}.png

        cvxlMM=`echo "($cslc - $origVXL) * $vxlres" | bc -l | awk ' { printf  "%6.2f\n", $0 } ' `
        mmY=$cvxlMM
        ystr=`echo "$ystr  $cvxlMM;"`

        if [ $doMM -eq 1 ]
        then
            montage -geometry +0+0 -font Palatino-Bold -background black  -fill LightYellow -pointsize 12 -label "$cvxlMM mm"   $tmpdir/Y_${cslc}.png $tmpdir/Y_${cslc}.png
        fi

        cnt=$(($cnt+1))
        if [ $cnt -eq 1 ]
        then
            cp $tmpdir/Y_${cslc}.png $tmpdir/Yset.png
        else
            pngappend $tmpdir/Yset.png + $pxl $tmpdir/Y_${cslc}.png $tmpdir/Yset.png
        fi

        if [ $do_thick -eq 1 ]
        then
            cslc=$(($cslc-1))
        fi

        if [ $SglVXL -eq 0 ]
        then
            fslmaths $tmpdir/all_slices -roi 0 $Xsz $cslc $slcwdth 0 $Zsz 0 1 $tmpdir/tmp_slcsel
            fslmaths $tmpdir/yslcsel -add $tmpdir/tmp_slcsel $tmpdir/yslcsel
        fi
    done

    echo "$ystr"
    echo "$ystr" >> $slcfl

    if [ $SglVXL -eq 0 ]
    then
        overlay 0 1 $bg_img $bgint $tmpdir/yslcsel 1 4 $tmpdir/Yslc_vol

        slicer    $tmpdir/Yslc_vol -s $slcsc $sdlbl -x 0.4   $tmpdir/YselX.png -z 0.6 $tmpdir/YselZ.png
        pngappend $tmpdir/YselX.png - 0    $tmpdir/YselZ.png $tmpdir/Ysel.png
        pngappend $tmpdir/Ysel.png  + $pxl $tmpdir/Yset.png  $tmpdir/Yset.png
    fi

    png_str="$png_str $tmpdir/Yset.png"
    set_cnt=$(($set_cnt+1))
fi

# Z
if [ $numZ -gt 0 ]
then
    origMM=`fslhd $bg_img | grep sto_xyz:3 | awk ' { if($5>=0) { print $5} else {print $5*-1 }}'`
    vxlres=`fslval $bg_img pixdim3`
    origVXL=` echo "$origMM / $vxlres" | bc -l | awk ' { printf  "%.0f\n", $0 } '`

    zstr="Z slices [mm]:"

#    zslices=""
    if [ $SglVXL -eq 0 ]
    then
        fslmaths $tmpdir/all_slices -mul 0 $tmpdir/zslcsel -odt char
    fi
    cnt=0
    for cslc in $zslc
    do
        if [ $cslc -gt $Zsz ]
        then
            echo ""
            echo "ERROR: Selected slice <$cslc> exceed number of slices in Z dimension"
            echo ""
            rm -r $tmpdir
            exit
        fi

        slicer $tmpdir/curr_img -s $scl -u -z -$cslc $tmpdir/Z_${cslc}.png

        cvxlMM=`echo "($cslc - $origVXL) * $vxlres" | bc -l | awk ' { printf  "%6.2f\n", $0 } ' `
        mmZ=$cvxlMM
        zstr=`echo "$zstr  $cvxlMM;"`

        if [ $doMM -eq 1 ]
        then
            montage -geometry +0+0 -font Palatino-Bold -background black  -fill LightYellow -pointsize 12 -label "$cvxlMM mm"   $tmpdir/Z_${cslc}.png $tmpdir/Z_${cslc}.png
        fi

        cnt=$(($cnt+1))
        if [ $cnt -eq 1 ]
        then
            cp $tmpdir/Z_${cslc}.png $tmpdir/Zset.png
        else
            pngappend $tmpdir/Zset.png + $pxl $tmpdir/Z_${cslc}.png $tmpdir/Zset.png
        fi

        if [ $do_thick -eq 1 ]
        then
            cslc=$(($cslc-1))
        fi

        if [ $SglVXL -eq 0 ]
        then
            fslmaths $tmpdir/all_slices -roi 0 $Xsz 0 $Ysz $cslc $slcwdth 0 1 $tmpdir/tmp_slcsel
            fslmaths $tmpdir/zslcsel -add $tmpdir/tmp_slcsel $tmpdir/zslcsel
        fi
    done

    echo "$zstr"
    echo "$zstr" >> $slcfl

    if [ $SglVXL -eq 0 ]
    then
        overlay 0 1 $bg_img $bgint $tmpdir/zslcsel 1 4 $tmpdir/Zslc_vol

        slicer $tmpdir/Zslc_vol -s $slcsc  $sdlbl -x 0.4     $tmpdir/ZselX.png -y 0.5 $tmpdir/ZselY.png
        pngappend $tmpdir/ZselX.png - 0    $tmpdir/ZselY.png $tmpdir/Zsel.png
        pngappend $tmpdir/Zsel.png  + $pxl $tmpdir/Zset.png  $tmpdir/Zset.png
    fi

    png_str="$png_str $tmpdir/Zset.png"
    set_cnt=$(($set_cnt+1))
fi

#----------------------------------------------------------------------#

if [ $ovly_stat -eq 1 ]
then
    declare -a zthr=($smint)

    text2png "${zthr[0]}" $tmpdir/lowZ.gif 14
    text2png "${zthr[1]}" $tmpdir/high.gif 14


    if [ $do_neg -eq 1 ]
    then
        text2png "-${zthr[0]}" $tmpdir/nlowZ.gif 14
        text2png "-${zthr[0]}" $tmpdir/nhigh.gif 14
        pngappend $tmpdir/nhigh.gif + 5 $FSLDIR/etc/luts/ramp2.gif + 10 $tmpdir/nlowZ.gif + 25 $tmpdir/lowZ.gif + 5 $FSLDIR/etc/luts/ramp.gif + 5 $tmpdir/high.gif $tmpdir/zinfo.gif
    else
        pngappend $tmpdir/lowZ.gif + 5 $FSLDIR/etc/luts/ramp.gif + 5 $tmpdir/high.gif $tmpdir/zinfo.gif
    fi

    convert $tmpdir/zinfo.gif $tmpdir/zinfo.png
fi

#----------------------------------------------------------------------#
if [ $set_cnt -gt 1 ]
then
    if [ $SglVXL -eq 1 ]
    then
        xstr=`printf "X: %6d [%6.2f mm]" $xslc $mmX`
        ystr=`printf "Y: %6d [%6.2f mm]" $yslc $mmY`
        zstr=`printf "Z: %6d [%6.2f mm]" $zslc $mmZ`

        text2png "$xstr" $tmpdir/Xvxlpos.png 12
        text2png "$ystr" $tmpdir/Yvxlpos.png 12
        text2png "$zstr" $tmpdir/Zvxlpos.png 12

        pngappend $tmpdir/Xvxlpos.png - 5 $tmpdir/Yvxlpos.png - 5 $tmpdir/Zvxlpos.png $tmpdir/slcinfo.png

        if [ $ovly_stat -eq 1 ]
        then
            pngappend $tmpdir/slcinfo.png - 5 $tmpdir/zinfo.png $tmpdir/slcinfo.png
        fi

        pngappend $tmpdir/selZ.png + 5 $tmpdir/selY.png   +  5 $tmpdir/selX.png      $tmpdir/SLCsel.png
        pngappend $tmpdir/SLCsel.png   -  5 $tmpdir/slcinfo.png   $tmpdir/SLCsel.png
        pngappend $tmpdir/Yset.png - 0 $tmpdir/Zset.png   $tmpdir/tmp_out1.png
        pngappend $tmpdir/Xset.png - 0 $tmpdir/SLCsel.png $tmpdir/tmp_out2.png
        pngappend $tmpdir/tmp_out1.png + 0 $tmpdir/tmp_out2.png $outnm
    else
        cnt=0
        for cstr in $png_str
        do
            cnt=$(($cnt+1))
            if [ $cnt -eq 1 ]
            then
                appstr="pngappend $cstr"
            else
                appstr="$appstr - $pxl $cstr"
            fi
        done
        appstr="$appstr $outnm"

        eval $appstr
    fi
else
    cp $png_str $outnm
fi

if [ $SglVXL -eq 0 ]
then
    if [ $ovly_stat -eq 1 ]
    then
        pngappend $outnm - $tmpdir/zinfo.png $outnm
    fi
fi
#----------------------------------------------------------------------#
if [ $do_keep -eq 0 ]
then
    rm -r $tmpdir
fi


