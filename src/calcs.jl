
# Test for hand type
"""
    isstraight(hand::Union{Hand,Vector{Card}})
    isstraight(ranks::Vector)

Tests whether `hand` is a straight
"""
isstraight(hand::Union{Hand,Vector{Card}}) = isstraight([Cards.rank(x).i for x in hand])
function isstraight(ranks::Vector)
    r = sort(ranks)
    r[1] == r[2] - 1 == r[end] - 2 || r[1] == 2 && r[2] == 3 && r[3] == 14
end

"""
    isflush(hand)

Tests whether `hand` is a flush
"""
function isflush(hand)
    length(unique(Cards.suit.(hand))) == 1
end

"""
    isprial(hand)

Tests whether `hand` is a prial
"""
isprial(hand) = all(Ref(Cards.rank.(hand)[1]) .== Cards.rank.(hand))

"""
    beats(hand1,hand2)

Tests whether `hand1` beats `hand2`
"""
beats(hand1, hand2) = getStrength(hand1) > getStrength(hand2)

"""
    draws(hand1,hand2)

Tests whether `hand1` draws with `hand2`
"""
draws(hand1, hand2) = getStrength(hand1) == getStrength(hand2)

"""
    winner(hand1,hand2)

Tests whether `hand1` draws with `hand2`
"""
function winner(hand1,hand2)
    s1 = getStrength(hand1)
    s2 = getStrength(hand2)
    if s1 > s2
        1
    elseif s2 > s1
        2
    else
        0
    end
end
getStrength(hand) = strength[handKey(hand)]

handQualifies(hand) = getStrength(hand) >= qualstrength

"""
    handtypes(deck)

Enumerates all of the hand types from the `deck`
"""
function handtypes(deck)
    
    rankscnt = sum(deck,dims=1)
    suitscnt = sum(deck,dims=2)
    totalcombos = begin
        v = sum(deck)
        v*(v-1)*(v-2)÷3÷2
    end
    prials = sum([x*(x-1)*(x-2)÷3÷2 for x in rankscnt])
    straightflushes = begin
        v = 0
        for suit in 1:4
            c = [deck[suit,13],deck[suit,:]...]
            v += sum([prod(c[i:i+2]) for i in 1:12])
        end
        v
    end
    straights = begin
        c = [rankscnt[end],rankscnt...]
        sum([prod(c[i:i+2]) for i in 1:12]) - straightflushes
    end
    flushes = begin
        sum([x*(x-1)*(x-2)÷3÷2 for x in suitscnt]) -straightflushes
    end
    pairs = begin
        sum([x*(x-1)÷2 * (sum(rankscnt[1:x-1])+sum(rankscnt[x+1:end])) for x in rankscnt])
    end
    highcards = begin
        totalcombos - pairs - flushes - straights - straightflushes - prials
    end

    [highcards,pairs,flushes,straights,straightflushes,prials]
end

"""
    braghandtypes(deck)

Enumerates all of the hand types from the `deck` separating out
the non-qualifying brag hands.
"""
function braghandtypes(deck)
    alltypes = handtypes(deck)
    lowcards = begin
        a = copy(deck)
        a[:,11:13] .= 0
        a
    end
    nonqual = handtypes(lowcards)
    [nonqual[1],alltypes[1]-nonqual[1],alltypes[2:end]...]
end

const RANKS = "23456789TJQKA"
const SUITS = "cdhs"
const CARDS = [r*s for s in SUITS, r in RANKS]
const carddeck = [Card(r*s) for s in SUITS, r in RANKS]
Deck() = fill(1,(4,13))


"""
    deal!(deck,cards::String)

Removes (deals) the cards from the deck.
"""
function deal!(deck,cards::String)
    for x in 1:length(cards)÷2
        deck[findfirst(==(cards[x*2-1:x*2]),CARDS)] = 0
    end
end
"""
    opponenthands(hand)

Enumerates the opponenthand types when hand is removed from the
standard deck.
"""
function opponenthands(hand)
    deck = Deck()
    deal!(deck,hand)
    braghandtypes(deck)
end


function comboTypes(hand)
    notqual = 0
    lose = 0
    draw = 0
    win = 0
    currdeck = filter(x->!in(x,hand),carddeck)
    # Grouping Combos is 3x slower
    for dealer in combinations(currdeck,3)
        if handQualifies(dealer)
            if beats(hand, dealer)
                win += 1
            elseif draws(hand, dealer)
                draw += 1
            else
                lose += 1
            end
        else
            notqual += 1
        end
    end
    return [notqual, lose, draw, win]
end

sortedRanks(hand) = sort([Cards.rank(c).i for c in hand],rev=true)
handKey(hand) = (sortedRanks(hand)..., isflush(hand))
percentile(hand) = perc[handkey(hand)]


const strength = Dict()
const perc = Dict()
const qualstrength = 0

function createLookup()

    combosum = 0
    i = 1

    function uplook(key, combos)
        global strength, perc
        strength[key] = i
        perc[key] = combosum / TOTAL_COMBOS  # Assuming TOTAL_COMBOS is defined
        combosum += combos
        i += 1
    end

    # High cards
    for r1 = 5:14
        for r2 = 3:r1-1
            for r3 = 2:r2-1
                if !isstraight([r1, r2, r3])
                    key = (r1, r2, r3, false)
                    combos = HIGH_CARD_HAND_COMBOS
                    uplook(key, combos)
                end
            end
        end
    end
    println("High cards:", combosum)
    lc = combosum
    # Pairs
    for r1 = 2:14
        for r2 = 2:14
            if r1 != r2
                if r1 > r2
                    key = (r1, r1, r2, false)
                else
                    key = (r2, r1, r1, false)
                end
                combos = PAIR_HAND_COMBOS
                uplook(key, combos)
            end
        end
    end
    println("Pairs:", combosum-lc)
    lc = combosum
    # Flushes
    for r1 = 5:14
        for r2 = 3:r1-1
            for r3 = 2:r2-1
                if !isstraight([r1, r2, r3])
                    key = (r1, r2, r3, true)
                    combos = FLUSH_HAND_COMBOS
                    uplook(key, combos)
                end
            end
        end
    end
    println("Flushes:", combosum-lc)
    lc = combosum
    # Straights
    for r1 = 3:14
        if r1 == 3
            key = (14, 3, 2, false)
        else
            key = (r1, r1-1, r1-2, false)
        end
        combos = STRAIGHT_HAND_COMBOS
        uplook(key, combos)
    end
    println("Straights:", combosum-lc)
    lc = combosum
    # Straight Flushes
    for r1 = 3:14
        if r1 == 3
            key = (14, 3, 2, true)
        else
            key = (r1, r1-1, r1-2, true)
        end
        combos = STRAIGHT_FLUSH_HAND_COMBOS
        uplook(key, combos)
    end
    println("Straight Flushes:", combosum-lc)
    lc = combosum
    # Prials (non 3)
    for r1 = 2:14
        if r1 != 3
            key = (r1, r1, r1, false)
            combos = PRIAL_HAND_COMBOS
            uplook(key, combos)
        end
    end
    # PRIAL of Threes
    key = (3, 3, 3, false)
    combos = PRIAL_HAND_COMBOS
    uplook(key, combos)
    println("Prials:", combosum-lc)

    global qualstrength = getStrength(Hand("Qc3s2d"))
end

function expectedValuePlay(hand,drawwins=false)
    cs = comboTypes(hand)
    win = 0
    totalcombos = 0
    for c in cs
        totalcombos += c
    end
    win += cs[1]
    win -= cs[2] * 2
    win += drawwins * cs[3] * 2
    win += cs[4] * 2
    return (win / totalcombos) + anteBonus(hand)
end

function anteBonus(hand)
    if isprial(hand)
        return anteBonusD.prial
    end
    if isstraight(hand)
        if isflush(hand)
            return anteBonusD.straightflush
        else
            return anteBonusD.straight
        end
    end
    return 0
end

function gameValue(deck, drawwins=false)
    ev = 0
    cnt = 0
    totalbet = 0
    for (player,combos) in groupCombos(deck)
        if handQualifies(player)
            evp = expectedValuePlay(player, drawwins)
        else
            evp = -2
        end
        if evp > -1
            ev += evp*combos
            totalbet += 1*combos
        else
            ev += -1*combos
        end
        cnt += 1*combos
        if cnt % 100 == 0
            println("Evaluated ", cnt, " hands.")
        end
    end
    return ev / cnt, (ev,totalbet,cnt)
end

function groupCombo(hand)
    sh = sort(collect(hand),by=Cards.rank,rev=true)
    suits = Dict(Cards.suit(sh[1])=>Suit(0))
    ret = [Cards.rank(sh[1])*Suit(0)]
    currs = 1
    for c in sh[2:end]
        s = Cards.suit(c)
        if haskey(suits,s)
            push!(ret,Cards.rank(c)*suits[s])
        else
            push!(ret,Cards.rank(c)*Suit(currs))
            suits[s] = Suit(currs)
            currs += 1
        end
    end
    ret
end

function groupCombos(deck)
    freqdict(groupCombo.(combinations(deck,3)))
end

freqdict(v) = Dict(x=>count(==(x),v) for x in unique(v))