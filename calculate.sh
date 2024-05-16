. $WM_PROJECT_DIR/bin/tools/RunFunctions

application=$(getApplication)

# Конвертация сетки, проверка, масштабирование
rm -r postProcessing*
rm -r 0
cp -r 0.orig 0
runApplication -o\
    ideasUnvToFoam Mesh_simple.unv
runApplication -o\
    checkMesh -allGeometry -allTopology
runApplication -o\
    transformPoints "scale=(1e-06 1e-06 1e-06)"

#Задание типов для геометрических групп
runApplication -o\
    foamDictionary\
        constant/polyMesh/boundary\
        -entry entry0/wall_f/type\
        -set symmetryPlane
runApplication -a\
    foamDictionary\
        constant/polyMesh/boundary\
        -entry entry0/wall_b/type\
        -set wall
runApplication -a\
    foamDictionary\
        constant/polyMesh/boundary\
        -entry entry0/defaultFaces/type\
        -set wall

# Инициализация параллельного решения
runApplication -a\
    foamDictionary\
        system/decomposeParDict\
        -entry numberOfSubdomains -set 4
runApplication -a\
    foamDictionary\
        system/decomposeParDict\
        -entry method\
        -set scotch
runApplication -o\
    decomposePar -force
runParallel -o\
    renumberMesh -overwrite

# граничные условия для начального приближения
# обратное подключение
# скорость
runParallel -a\
    foamDictionary\
        0/U\
        -entry boundaryField/ent\
        -set "{type fixedValue; value uniform (5 0 0);}"
runParallel -a\
    foamDictionary\
        0/U\
        -entry boundaryField/out\
        -set "{type zeroGradient;}"
# давление
runParallel -a\
    foamDictionary\
        0/p\
        -entry boundaryField/ent\
        -set "{type zeroGradient;}"
runParallel -a\
    foamDictionary\
        0/p\
        -entry boundaryField/out\
        -set "{
            type     totalPressure;
            p0		uniform 0;
        }"

# кинетическая энергия
runParallel -a\
    foamDictionary\
        0/k\
        -entry boundaryField/ent\
        -set "{
            type        turbulentIntensityKineticEnergyInlet;
            intensity   0.06;
            value       uniform 1;
        }"
runParallel -a\
    foamDictionary\
        0/k\
        -entry boundaryField/out\
        -set "{type            zeroGradient;}"

# nut
runParallel -a\
    foamDictionary\
        0/nut\
        -entry boundaryField/ent\
        -set "{
            type        calculated;
            value       uniform 0;
        }"
runParallel -a\
    foamDictionary\
        0/nut\
        -entry boundaryField/out\
        -set "{
            type        calculated;
            value       uniform 0;
        }"
# epsilon
runParallel -a\
    foamDictionary\
        0/epsilon\
        -entry boundaryField/ent\
        -set "{
            type            turbulentMixingLengthDissipationRateInlet;
            mixingLength    0.0015;
            value       uniform 200;
        }"
runParallel -a\
    foamDictionary\
        0/epsilon\
        -entry boundaryField/out\
        -set "{type     zeroGradient;}"

runParallel -o\
    potentialFoam
runParallel -o\
    applyBoundaryLayer\
    -Cbl 0.2

# Граничные условия для алгоритма simple
runParallel -a\
    foamDictionary\
        0/U\
        -entry boundaryField/ent\
        -set "{
            type                flowRateInletVelocity;
            profile             turbulentBL;
            volumetricFlowRate  1.25e-6;
            value               uniform (0 0 0);
        }"
runParallel -a\
    foamDictionary\
        0/U\
        -entry boundaryField/out\
        -set "{type zeroGradient;}"
runParallel -o\
    $application

cp -r postProcessing postProcessing_reverse

# прямое подключение
rm -r 0
cp -r 0.orig 0
runApplication -o\
    decomposePar -force
runParallel -o\
    renumberMesh -overwrite

runParallel -a\
    foamDictionary\
        0/U\
        -entry boundaryField/out\
        -set "{type fixedValue; value uniform (5 0 0);}"
runParallel -a\
    foamDictionary\
        0/U\
        -entry boundaryField/ent\
        -set "{type zeroGradient;}"

# давление
runParallel -a\
    foamDictionary\
        0/p\
        -entry boundaryField/out\
        -set "{type zeroGradient;}"
runParallel -a\
    foamDictionary\
        0/p\
        -entry boundaryField/ent\
        -set "{
            type     totalPressure;
            p0		uniform 0;
        }"

# кинетическая энергия
runParallel -a\
    foamDictionary\
        0/k\
        -entry boundaryField/out\
        -set "{
            type        turbulentIntensityKineticEnergyInlet;
            intensity   0.06;
            value       uniform 1;
        }"
runParallel -a\
    foamDictionary\
        0/k\
        -entry boundaryField/ent\
        -set "{type            zeroGradient;}"

# nut
runParallel -a\
    foamDictionary\
        0/nut\
        -entry boundaryField/ent\
        -set "{
            type        calculated;
            value       uniform 0;
        }"
runParallel -a\
    foamDictionary\
        0/nut\
        -entry boundaryField/out\
        -set "{
            type        calculated;
            value       uniform 0;
        }"
# epsilon
runParallel -a\
    foamDictionary\
        0/epsilon\
        -entry boundaryField/out\
        -set "{
            type            turbulentMixingLengthDissipationRateInlet;
            mixingLength    0.0015;
            value       uniform 200;
        }"
runParallel -a\
    foamDictionary\
        0/epsilon\
        -entry boundaryField/ent\
        -set "{type     zeroGradient;}"

runParallel -o\
    potentialFoam
runParallel -o\
    applyBoundaryLayer\
    -Cbl 0.2
runParallel -a\
    foamDictionary\
        0/U\
        -entry boundaryField/out\
        -set "{
            type                flowRateInletVelocity;
            profile             turbulentBL;
            volumetricFlowRate  1.25e-6;
            value               uniform (0 0 0);
        }"
runParallel -a\
    foamDictionary\
        0/U\
        -entry boundaryField/ent\
        -set "{type zeroGradient;}"
runParallel -o\
    $application

cp -r postProcessing postProcessing_direct

exit 0
