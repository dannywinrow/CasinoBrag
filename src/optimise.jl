
function comboTypesH(hand)
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