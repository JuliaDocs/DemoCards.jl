# TODO: we can manage themes like TestImages.jl

const card_section_template = mt"""
```@raw html
<div class="card-section">
```

{{{cards}}}

```@raw html
</div>
```
"""

const card_template = mt"""
```@raw html
<div class="card">
<div class="card-cover">
<p class="card-description">{{description}}</p>
```
[![card-cover-image](covers/{{name}})](@ref {{id}})
```@raw html
</div>
<div class="card-text">
```

[{{title}}](@ref {{id}})

```@raw html
</div>
</div>
```

"""

const max_coversize = (220, 200)
const theme_minimal = """
.card-section {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  align-content: space-between;
}

.card:hover{
  box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.4), 0 6px 20px 0 rgba(0, 0, 0, 0.1);
}

.card {
    width: 210px;
    max-height: 400px;
    margin: 10px 15px;
    box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);
    transition: 0.3s;
    border-radius: 5px;
}

.card-text {
    padding: 0 15px;
}

img[alt="card-cover-image"] {
    width: 100%;
}

.card-cover {
    width: $(max_coversize[2])px;
    height: $(max_coversize[1])px;
    padding: 5px;
    box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.2);
    transition: 0.3s;
    border-radius: 5px;
    display:block;
    margin:auto;
}

.card-cover .card-description {
    opacity: 0;
    z-index: -1;
    position: absolute;
    top: 25%;
    left: 140%;
    width: 100%;
    transform: translate(-50%, -50%);
    padding: 10px;
    border-radius: 5px;
    background: rgba(0, 0, 0, 0.8);
    color: #fff;
    text-align: center;
    font-size: 14px;
}

.card-cover:hover .card-description{
    z-index: 3;
    opacity: 1;
}

"""

function read_cardtheme(theme::AbstractString)
    if theme == "minimal"
        return theme_minimal
    else
        throw(ArgumentError("no theme $(theme) found."))
    end
end
