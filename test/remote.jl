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

        @testset "LocalRemoteSection" begin
            # there will be warnings due to lack of cover images, but we can just safely ignore them
            @suppress_err preview_demos(abs_root; theme="grid")
            page_dir = @suppress_err preview_demos(abs_root; require_html=false)
            @test readdir(page_dir) == ["hidden_section", "remote_card_mixed", "remote_card_mixed_order", "remote_card_simplest", "remote_subfolder"]
        end

        # Because `preview_demos` eagerly converts local remote files as direct entries
        # we also need to test it on plain "makedemos" to ensure that it works on `docs/make.jl`
        @testset "application" begin
            mktempdir() do root
                tmp_root = joinpath(root, "remote")
                mkpath(tmp_root)
                cp(abs_root, tmp_root, force=true)

                # override relative paths as absolute paths
                # -- I'm too lazy to figure a solution so just copy and paste an ad-hoc solution here :(
                for (dir, entry_names) in [
                    (".", ["hidden_section", ]),
                    ("remote_subfolder", ["hidden_section", ]),
                    ("remote_card_mixed", ["julia_card1.jl", "markdown_card1.md"]),
                    ("remote_card_mixed_order", ["julia_card2.jl", "markdown_card2.md"]),
                    ("remote_card_simplest", ["julia_card3.jl", "markdown_card3.md"]),
                ]
                    config_file = joinpath(tmp_root, dir, "config.json")
                    config = JSON.parsefile(config_file)
                    for x in entry_names
                        config["remote"][x] = normpath(abs_root, dir, config["remote"][x])
                    end
                    open(config_file, "w") do io
                        JSON.print(io, config)
                    end
                end

                
                function flatten_walkdir(root_dir)
                    contents = []
                    for (root, dirs, files) in walkdir(root_dir)
                        push!(contents, root)
                        append!(contents, map(x->joinpath(root, x), dirs))
                        append!(contents, map(x->joinpath(root, x), files))
                    end
                    return unique(map(x->relpath(x, root_dir), contents))
                end

                # we generate twice using `makedemos` and `preview_demos` and compare the results
                templates, theme = @suppress_err cardtheme(root=root)
                path, post_process_cb = @suppress_err makedemos(tmp_root, templates, root=root)
                page_dir = joinpath(root, "src", dirname(path))
                plain_contents = flatten_walkdir(page_dir)

                page_dir = @suppress_err preview_demos(abs_root; require_html=false)
                preview_contents = flatten_walkdir(page_dir)
                @test sort(setdiff(plain_contents, preview_contents)) == ["covers", "covers/democards_logo.svg", "index.md"]
            end
        end
    end
end
