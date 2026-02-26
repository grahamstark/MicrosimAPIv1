
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


function inrange(x,ranges){
  for(var i = 0; i < ranges.length; i++){
    if ((x > ranges[i][0])&&(x<ranges[i][1])){
      return true;
    }
  }
  return false;
}

/*
Plot.plot({
  aspectRatio: 1,
  x: {label: "Age (years)"},
  y: {
    grid: true,
    label: "← Women · Men →",
    labelAnchor: "center",
    tickFormat: Math.abs
  },
  marks: [
    Plot.dot(
      congress,
      Plot.stackY2({
        x: (d) => 2023 - d.birthday.getUTCFullYear(),
        y: (d) => d.gender === "M" ? 1 : -1,
        fill: "gender",
        title: "full_name"
      })
    ),
    Plot.ruleY([0]),
    Plot.ruleX([40],{stroke:"red", title:"Median"}),
    Plot.textX([40], { text:["Median"], frameAnchor:"top"})
  ]
})


test = (bin) => bin.some((d) => inrange( d.weight, [[45,55],[70,99]] ));
*/

function make_thumb( marks_array ){
    return Plot.plot({
        x: {axis: null},
        y: {axis: null},
        marks: marks_array,
        width: 120,
        height: 80
    });
}


function drawLorenz( quantileData ){

    var points0 = d3.zip(quantileData.item[0].columns[0], quantileData.item[0].columns[1]);
    var points1 = d3.zip(quantileData.item[1].columns[0], quantileData.item[1].columns[1]);
    points0.unshift([0,0]);
    points1.unshift([0,0]);
    console.log( points0 );
    console.log( points1 );

    const lorenz0 = Plot.line( points0, {stroke:"red", curve: "catmull-rom", label:"Pre"} );
    const lorenz1 = Plot.line( points1, {stroke:"blue", curve: "catmull-rom", label:"Post"} );
    const equality = Plot.line( [[0,0],[1,1]], {stroke:"#aaa", label:"Equality"})
    const lorcurve = Plot.plot(
        { marks: [ lorenz0, lorenz1, equality],
          //title: "For charts, an informative title",
          //subtitle: "Subtitle to follow with additional context",
          caption: "Figure 1. A Lorenz Curve",
          color: {legend: true},
          x: {label: "Population Share", grid:true },
          y: {label: "Income Share", grid:true }
    })
    const thumbnail = make_thumb( [lorenz0, lorenz1, equality]);
    return [lorcurve, thumbnail];
}

function drawDecileBarChart( deciles1, deciles0 ){
    var decs = Array.from( deciles1 );
    // drawing the differences between 1 and 0
    for( var i = 0; i < decs.length; i++ ){
        decs[i] -= deciles0[i];
    }
    console.log( "deciles1", deciles1, "deciles0", deciles0, "decs", decs );
    const bars = Plot.barY( decs )
    const decplot =  Plot.plot(
        { marks: [ bars ],
          //title: "For charts, an informative title",
          //subtitle: "Subtitle to follow with additional context",
          caption: "Figure 2. Gains By Decile",
          color: {legend: true},
          x: {label: "Decile", grid:true },
          y: {label: "Change £s pw.", grid:true }
    })
    const thumbnail = make_thumb( [bars])
    return [decplot, thumbnail];
}


function draw1MR( title, xy, median, mean, colour ){
    console.log( "xy", xy, "median", median, "mean", mean );
    const bars = Plot.rectY( xy,
        {
            x1:"x1",
            x2:"x2",
            y:"y",
            stroke:"grey",
            fill:colour
        });
    const medl = Plot.ruleX( [median], {stroke: "darkblue"});
    const meanl = Plot.ruleX( [mean], {stroke: "darkred"});
    const plot =  Plot.plot(
        { marks:
            [bars, medl, meanl],
            title: "",
            width: 500,
            height: 500,
            x: {label: "METR(%)", grid:true },
            y: {label: "People.", grid:true}
    });
    const thumbnail = make_thumb( [bars,medl, meanl]) //,medl, meanl])
    return [plot, thumbnail];
}

/*
caption: title,
          x: {label: "METR(%)", grid:true, fill:'steelblue' },
          y: {label: "People.", grid:true }
*/

function drawMRHist( title, data1, data0 ){
    var xy0 = [];
    var xy1 = [];
    // convert one width to gaps from top breaks - assume 0 1 same gaps
    for( var i = 1; i <= data0.x.length-2; i++ ){
        var d1 = i == (data0.x.length-2) ? 120 : data0.x[i+1];
        xy0.push( {x1:data0.x[i], x2:d1, y:data0.y[i]});
        xy1.push( {x1:data0.x[i], x2:d1, y:data1.y[i]});
    }
    console.log( "xy0", xy0, "xy1", xy1 );
    // over 100 one - just arnitrariy so it doesn't go to infinity
    draw0 = draw1MR( "Figure 3a: Effective Marginal Tax Rates (METRS), Pre", xy0, data0.median, data0.mean, "#559" )
    draw1 = draw1MR( "Figure 3a: Effective Marginal Tax Rates (METRS), Post", xy1, data1.median, data1.mean, "#595" )
    return draw0.concat( draw1 );
}

/**
function drawMRHistx( title, data1, data0 ){
    var width = Array.from( data0.x )
    // chop off bottom zeros for negative MRs
    width = width.slice(1,width.length-1);
    weights0 = data0.y.slice(1,data0.y.length);
    weights1 = data1.y.slice(1,data1.y.length);
    // convert one width to gaps from top breaks - assume 0 1 same gaps
    for( var i = 1; i <= width.length; i++ ){
        // since data.x is 1 longer
        width[i-1] = data0.x[i+1]-data0.x[i];
    }
    // over 100 one - just arnitrariy so it doesn't go to infinity
    width[width.length-1] = 20; // Math.min( Math.abs(width[0]), width[1])
    console.log( "width", width, "weights", weights0 );
    xy0 = jsonify(width, weights0, "width", "count" );
    xy1 = jsonify( width, weights1, "width", "count" );
    draw0 = draw1MR( "Figure 3a: Effective Marginal Tax Rates (METRS), Pre", xy0, data0.median, data0.mean )
    draw1 = draw1MR( "Figure 3a: Effective Marginal Tax Rates (METRS), Post", xy1, data1.median, data1.mean )
    return draw0.concat( draw1 );
}


function draw1MRx( title, xy, median, mean ){
    console.log( "xy", xy );
    bars = Plot.rectY(xy,{x:"width", y:"count", fill:"none",stroke:"black"});
    medl = Plot.ruleX( [median], {stroke: "red"});
    meanl = Plot.ruleX( [mean], {stroke: "blue"});

    const plot =  Plot.plot(
        { marks:
            [bars, medl, meanl],
          caption: title,
          x: {label: "METR(%)", grid:true, fill:'steelblue' },
          y: {label: "People.", grid:true }
    });
    const thumbnail = make_thumb( [bars]) //,medl, meanl])
    return [plot, thumbnail];
}

function jsonify(x,y,nx,ny){
    var o = [];
    for( var i = 0; i < x.length; i++ ){
        o.push( {"x1":x[i], "y":y[i]})
    }
    return o;
}
*/
