using DataFrames, CSV

function gameCombosArray(deck)
    [player => (combos,comboTypes(player)) for (player,combos) in groupCombos(deck)]
end

ev(r) = (r.notqual+2*(r.win-r.lose)) / binomial(49,3) + r.antebonus

function constructComboTypesDF()
    gca = gameCombosArray(carddeck)
    hands = [x[1] for x in gca]
    combos = [x[2][1] for x in gca]
    notqual =  [x[2][2][1] for x in gca]
    losses = [x[2][2][2] for x in gca]
    draw = [x[2][2][3] for x in gca]
    wins = [x[2][2][4] for x in gca]
    
    rdf = DataFrame(hand=hands,combos=combos,notqual=notqual,losses=losses,draw=draw,win=wins)
    rdf.antebonus = anteBonus.(rdf.hand)
    rdf.ev = ev.(r for r in eachrow(rdf))
    sort!(rdf)
end

function loadcombotypes()
    rdf = CSV.read("./src/Brag/data/comboTypes.csv",DataFrame)
    rdf.hand = eval.(Meta.parse.(rdf.hand))
    rdf
end

function savecombotypes(rdf)
    CSV.write("./src/Brag/data/comboTypes.csv",rdf)
end

function gameev(rdf)
    sum(max.(rdf.ev,-1) .* rdf.combos) / sum(rdf.combos)
end