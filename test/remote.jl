@testset "RemotePath" begin
    root = "assets"
    abs_root = joinpath(pwd(), root, "remote")

    @testset "LocalRemote" begin
        @testset "LocalRemoteCard" begin
            for (numcards, dir) in [
                # As long as it does not error, we believe the order is respected
                (5, "remote_card_mixed_order"),
                (5, "remote_card_mixed"),
                (4, "remote_card_simplest")
            ]
                # there will be warnings due to lack of cover images, but we can just safely ignore them
                @suppress_err preview_demos(joinpath(abs_root, dir); theme="grid")
                page_dir = @suppress_err preview_demos(joinpath(abs_root, dir); require_html=false)
                files = readdir(joinpath(page_dir, dir))
                @test numcards == map(files) do f
                    splitext(f)[1]
                end |> length
            end
        end
    end
end
