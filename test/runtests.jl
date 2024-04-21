using Test

@testset "Straights" begin
    @test isstraight(Hand("4c5c6c")) == true
    @test isstraight(Hand("2cAc3c")) == true

end

@testset "Flushes" begin
    @test isflush(Hand("2cAc3c")) == true
end

@testset "Combos" begin
    @test sum(COMBO_TYPES) == TOTAL_COMBOS
    @test comboTypes(hand) = 2
end

@testset "rdf" begin
    rdf = loadcombotypes()
    @test sum(rdf.combos) == TOTAL_COMBOS
    @test sum(filter(x->x.antebonus==5,rdf).combos) == PRIAL_COMBOS
    @test sum(filter(x->x.antebonus==4,rdf).combos) == STRAIGHT_FLUSH_COMBOS
    @test sum(filter(x->x.antebonus==1,rdf).combos) == STRAIGHT_COMBOS
    @test all(==(binomial(49,3)), rdf.notqual .+ rdf.lose .+ rdf.draw .+ rdf.win)
end