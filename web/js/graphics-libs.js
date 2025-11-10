
const GOLDEN_RATIO = 1.618

function createLorenzCurve( targetId, quantiles, thumbnail ){
    var height = 300;
    console.log(quantiles)
    var xtitle = "Population Share";
    var ytitle = "Income Share";
    var title = "Lorenz Curve"
    if( thumbnail ){
        var height = 70;
        xtitle = "";
        ytitle = "";
        title = "";
    }
    var width = Math.trunc( GOLDEN_RATIO*height);
    var data=[];
    console.log( "lorenz_pre length" + quantiles[0].length );
    // deciles levels are rhs. so push a 0,0
    data.push( {"popn1":0, "pre":0 });
    for( var i = 0; i < quantiles[0].columns[0].length; i++){
        data.push( {
            "popn1":quantiles[0].columns[0][i], 
            "pre":quantiles[0].columns[1][i] });
    }
    // var data_post= [];
    data.push( {"popn2":0, "post":0 });
    for( var i = 0; i < quantiles[1].columns[0].length; i++){
        data.push( {
            "popn2":quantiles[1].columns[0][i], 
            "post":quantiles[1].columns[1][i] });
    }
    data.push( {"popn3":0.0, "base":0.0});
    data.push( {"popn3":1.0, "base":1.0});
    console.log( data );
    var gini_vg = {
        "$schema": "https://vega.github.io/schema/vega-lite/v3.json",
        "title": title,
        "width": width,
        "height": height,
        "description": title,
        "data": {"values": data }, // , "post":data_post
        "layer":[
            {
                "mark": "line",
                "encoding":{
                    "x": { "type": "quantitative",
                           "field": "popn1",
                           "axis":{
                               "title": xtitle
                           }},
                    "y": { "type": "quantitative",
                           "field": "pre",
                           "axis":{
                              "title": ytitle
                           } },
                    "color": {"value":"blue"}
                } // encoding
            }, // pre layer line
            {
                "mark": "line",
                "encoding":{
                    "x": { "type": "quantitative",
                           "field": "popn2",
                           "axis":{
                              "title": xtitle
                           }},
                    "y": { "type": "quantitative",
                           "field": "post",
                           "axis":{
                              "title": ytitle
                           } },
                   "color": {"value":"red"}
               } // encoding
           }, // post line
          { // diagonal in grey
               "mark": "line",
               "encoding":{
                   "x": { "type": "quantitative",
                          "field": "popn3" },
                   "y": { "type": "quantitative",
                          "field": "base" },
                   "color": {"value":"#ccc"},
                   "strokeWidth": {"value": 1.0}
                   // "strokeDash":
               } // encoding
           },
        ]
    }
    vegaEmbed( targetId, gini_vg );
}
 
function createDecileBarChart( targetId, result, thumbnail ){
    var height = 300;
    var xtitle = "Deciles";
    var ytitle = "Gains in £s p.w.";
    var title = "Gains By Decile"
    if( thumbnail ){
        var height = 70;
        xtitle = "";
        ytitle = "";
        title = "";
    }
    var width = Math.trunc( GOLDEN_RATIO*height);
    var data=[];
    console.log( "deciles" + result.gains_by_decile.toString());
    console.log( "lorenz_pre[2] length" + result.gains_by_decile.length );
    for( var i = 0; i < result.gains_by_decile.length; i++){
        var dec = (i+1);
        data.push( {"decile":dec, "gain":result.gains_by_decile[i] });
    }
    var deciles_vg = {
        "$schema": "https://vega.github.io/schema/vega-lite/v3.json",
        "title": title,
        "width": width,
        "height": height,
        "description": title,
        "data": {"values": data }, // , "post":data_post
        "mark": "bar",
        "encoding":{
            "x": { "type": "ordinal",
                   "field": "decile",
                   "axis":{
                      "title": xtitle
                   }
             },
            "y": { "type": "quantitative",
                   "field": "gain",
                   "axis":{
                      "title": ytitle
                   }
            }
        } // encoding
    }
    console.log( "deciles_vg=" + JSON.stringify(deciles_vg) );

    vegaEmbed( targetId, deciles_vg );
}
