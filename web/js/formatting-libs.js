
function formatTable( id, caption, headerRow, tableBody ){
    return `
    <table id='${id}' name='${id}' class='table table-sm table-striped'>
        <thead>
            <caption>
            ${caption}
            </caption>            
        </thead>
        <tr>${headerRow}</tr>
        <tbody>
            ${tableBody}
        </tbody>
    </table>
    `;
}

function fmt0( v ){
    return $.number( v );
}

function fmt2( v ){
    return $.number( v, 2 );
}

function moneyfmt( v ){
    return '&pound;'+fmt2(v);
}

function pctfmt( v ){
    return fmt2(v)+'%';
}

const OUT_SUBS = {
    'avch':'Average Change',
    'pct_change':"% Change",
    'total_transfer': 'Total Transfer &pound;mn'
};

/**
 * borrowed from Stack Exchange: https://stackoverflow.com/questions/196972/convert-string-to-title-case-with-javascript
 * @param {*} str 
 * @returns 
 */
function toTitleCase(str) {
  return str.replace(
    /\w\S*/g,
    text => text.charAt(0).toUpperCase() + text.substring(1).toLowerCase()
  );
}

function formatLabel( s ){
    if( ! isNaN(s)){ // thing is a number
        return s;
    }
    if(OUT_SUBS[s] !== undefined){ // thing is a predifined string
        return OUT_SUBS[s];
    }
    s = s.replaceAll( "_", " ");
    return toTitleCase(s);
}

function formatRow( rowLabel, rowCells ){
    return `
    <tr><th>${rowLabel}</th>${rowCells}</tr>
    `;
}

function formatJuliaDataframe( id, df, formatter ){
    var rowLabels = df.columns[0];
    var colLabels = df.colindex.names;
    var caption = ''
    if(df["metadata"] != undefined){
        caption = df.metadata.caption[0];
    }
    var tableBody = '';
    var headerRow = '';
    for( var c = 0; c < colLabels.length; c++){
        headerRow += `<th>${formatLabel(colLabels[c])}</th>`;
    }
    for( var r = 0; r < rowLabels.length; r++){
        var rowCells = "";
        for( var c = 1; c < df.columns.length; c++){ // 1st col is row label
            v = df.columns[c][r];
            vs = formatter(v)
            rowCells += `<td style='text-align:right'>${vs}</td>`;
        }
        tableBody += formatRow( formatLabel(rowLabels[r]), rowCells );
    }
    var t = formatTable( id, caption, headerRow, tableBody );
    // console.log( "created table as ", t )
    return t;
}

function formatGainLose(id, df ){
    return formatJuliaDataframe(id, df, fmt0);
}

const FAMDIR = "bisite" // old budget images; alternative is 'keiko' for VE images

const ARROWS_1 = {
    "nonsig"          : "",
    "positive_strong" : "<i class='bi bi-arrow-up-circle-fill'></i>",
    "positive_med"    : "<i class='bi bi-arrow-up-circle'></i>",
    "positive_weak"   : "<i class='bi bi-arrow-up'></i>",
    "negative_strong" : "<i class='bi bi-arrow-down-circle-fill'></i>",
    "negative_med"    : "<i class='bi bi-arrow-down-circle'></i>",
    "negative_weak"   : "<i class='bi bi-arrow-down'></i>" };

function formatAndClass( change ){
    var gnum = fmt2( Math.abs(change));
    var glclass = "";
    var glstr = ""
    if( change > 20.0 ){
        glstr = "positive_strong"
        glclass = "text-success"
    } else if (change > 10.0) {
        glstr = "positive_med"
        glclass = "text-success"
    } else if (change > 0.01) {
        glstr = "positive_weak"
        glclass = "text-success"
    } else if (change < -20.0) {
        glstr = "negative_strong"
        glclass = "text-danger"
    } else if (change < -10) {
        glstr = "negative_med"
        glclass = "text-danger"
    } else if (change < -0.01) {
        glstr = "negative_weak"
        glclass = "text-danger"
    } else {
        glstr = "nonsig"
        glclass = "text-body"
        gnum = "";
    }
    var changestr = gnum !== "" ? "&nbsp;"+ARROWS_1[glstr]+"&nbsp;&pound;"+gnum+"pw" : "No Change";
    return {"gnum":gnum, "glclass":glclass, "glstr":glstr, "changestr":changestr };
}

function make_example_card( res ){
    console.log( "make_example_card; res = ", res );
    var hh = res.household;
    var change = res.pres.bhc_net_income - res.bres.bhc_net_income;
    // ( gnum, glclass, glstr ) 
    var fc = formatAndClass( change );
    // i2sp = inctostr(res.pres.income )
    // i2sb = inctostr(res.bres.income )
    var card = `
    <div class='card' 
        style='width: 12rem;' 
        data-bs-toggle='modal' 
        data-bs-target='#${hh.picture}' >
            <div class='row'>
                <img src='images/families/${FAMDIR}/${hh.picture}.svg'  
                    width='130'
                    height='93'
                    alt='Picture of Family'/>                    
             </div>
            <div class='card-body'>
                <p class='$glclass'><strong>${fc.changestr}</strong></p>
                <h5 class='card-title'>${hh.label}</h5>
                <p class='card-text text-black'>${hh.description}</p>
            </div>
        </div><!-- card -->
    `;
    return card;
}

/**
 * Nicked from Stack overflow, again: https://stackoverflow.com/questions/1349404/generate-a-string-of-random-characters
 * @param {*} length 
 * @returns 
 */
function makeid(length){
    var result           = '';
    var characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    var charactersLength = characters.length;
    for ( var i = 0; i < length; i++ ) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    return result;
}

function hhsummary( hh ){
    var ten = formatLabel(hh.tenure);
    var rm = "Rent";
    var hc = fmt2( hh.gross_rent, commas=true, precision=2);
    if(hh.tenure == 'owner_occupier'){
        hc = fmt2(hh.mortgage_payment);
        rm = "Mortgage";
    }
    var table = `
    <table class='table table-sm'>
        <thead>
            <tr>
                <th></th><th style='text-align:right'></th>
            </tr>
        </thead>
        <tbody>
            <tr><th>Tenure</th><td style='text-align:right'>${ten}</td></tr>
            <tr><th>${rm}</th><td style='text-align:right'>${hc}</td></tr>
        </tbody>
    </table>`;
    return table;
}

function make_example_popups( res ){
    var pit =  formatJuliaDataframe( makeid(30), res.incsummary, fmt2 );
    var hhtab = hhsummary( res.household.hh );
    var modal = `
<!-- Modal -->
<div class='modal fade' id='${res.household.picture}' tabindex='-1' role='dialog' aria-labelledby='${res.household.picture}-label' aria-hidden='true'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      <div class='modal-header'>
      <h5 class='modal-title' id='${res.household.picture}-label'/>${res.household.label}</h5>
      <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
         
      </div> <!-- header -->
      <div class='modal-body'>
        <div class='row'>            
            <img src='images/families/${FAMDIR}/${res.household.picture}.svg'  
                width='195' height='140'
                alt='Picture of Family'
              />
            </div>
            <div class='col'>
                ${hhtab}
            </div>
        </div>
        
        ${pit}
          
      </div> <!-- body -->
    </div> <!-- content -->
  </div> <!-- dialog -->
</div><!-- modal container -->
`
    return modal;
}

function make_examples( exampleResults ){
    console.log( " make_examples; exampleResults", exampleResults );
    var cards = "<div class='card-group'>";
    for( var i = 0; i < exampleResults.length; i++ ){
        cards += make_example_card( exampleResults[i])
    }
    cards += "</div>"
    for( var i = 0; i < exampleResults.length; i++ ){
        cards += make_example_popups( exampleResults[i])
    }
    return cards;
}



function formatAndClassSummary( pre, post, delta, upIsGood, formatter ){
    prestr = formatter(pre);
    poststr = formatter(post);
    m = upIsGood ? 100 : -100;
    change = m*(delta/pre);
    var gnum = fmt2( Math.abs(delta));
    var glclass = "";
    var glstr = ""
    if( change > 20.0 ){
        glstr = "positive_strong"
        glclass = upIsGood ? "text-success" : "text-danger";
    } else if (change > 10.0) {
        glstr = "positive_med"
        glclass = upIsGood ? "text-success" : "text-danger";
    } else if (change > 0.01) {
        glstr = "positive_weak"
        glclass = upIsGood ? "text-success" : "text-danger";
    } else if (change < -20.0) {
        glstr = "negative_strong"
        glclass = upIsGood ? "text-danger" : "text-success";
    } else if (change < -10) {
        glstr = "negative_med"
        glclass = upIsGood ? "text-danger" : "text-success";
    } else if (change < -0.01) {
        glstr = "negative_weak"
        glclass = upIsGood ? "text-danger" : "text-success";
    } else {
        glstr = "nonsig"
        glclass = "text-body"
        gnum = "";
    }
    var changestr = gnum !== "" ? "&nbsp;"+ARROWS_1[glstr]+"&nbsp;"+gnum+"pw" : "No Change";
    return {"gnum":gnum, "glclass":glclass, "glstr":glstr, "changestr":changestr, 'prestr':prestr, 'poststr':poststr };
}


function summarycard( label, pre, post, delta, upIsGood, formatter ){
    var fc = formatAndClassSummary( pre, post, delta, upIsGood, formatter );
    return `
<div id='#${label}' class="card" style="width: 18rem;">
  <div class="card-body">
    <h5 class="card-title">${label}</h5>
    <p class="card-text ${fc.glclass}">${fc.changestr} pre: ${fc.prestr} post: ${fc.poststr}<p>
  </div>
</div>
    `;
}



/*

gainers	710249.4316886746
losers	4.3139657900036e6JS:4313965.7900036
no_change	418767.2673887266
ben1	2.7599549369699135e10JS:27599549369.699135
ben2	2.8069550519604668e10JS:28069550519.604668
tax1	3.689785996315472e10JS:36897859963.15472
tax2	4.033229246856358e10JS:40332292468.56358
palma1	0.9281274467034024
palma2	1.1535255723115374
gini1	0.2674798905761182
gini2	0.3055580593206566
pov_headcount1	0.1344091839937771
pov_headcount2	0.18173504816581115
Δtax	3.434432505408867e9JS:3434432505.408867
Δben	4.7000114990553284e8JS:470001149.90553284
net_cost	2.964431355503333e9JS:2964431355.503333
net_direct	2.964431355503334e9JS:2964431355.503334
Δpalma	0.225398125608135
Δgini	0.0380781687445384
Δpov_headcount	0.04732586417203405

*/

function makeSummaryBlock( id, res ){
    var sum = res[1];
    console.log( "makeSummaryBlock; sum = ", res );
    var fc = formatAndClass( sum.net_cost );
    var headline = `<p class='${fc.glclass}'>Net Cost of your changes: ${fc.changestr}</p>`;
    var glline = `<p>Gainers: <b> ${fmt0(sum.gainers)}</b> Losers: <b>${fmt0(sum.losers)}</b> Unchanged: <b>${fmt0(sum.no_change)}  </b> </p>`
    var cards = `<div id=${id} class='card-group'>`;
    cards += summarycard( "Direct Taxes £m", 
        sum.tax1/1000000, sum.tax2/1000000, sum.Δtax/1000000, true, fmt0 );
    cards += summarycard( "Benefit Spending £m", 
        sum.ben1/1000000, sum.ben2/1000000, sum.Δben/1000000, false, fmt0 );
    cards += summarycard( "Inequality (Gini Coefficient)", 
        sum.gini1, sum.gini2, sum.Δgini, false, fmt2 );
    cards += summarycard( "Inequality (Palma Index)", 
        sum.palma1, sum.palma2, sum.Δpalma, false, fmt2 );
    cards += summarycard( "Poverty (Headcount))", 
        sum.pov_headcount1, sum.pov_headcount2, sum.Δpov_headcount, false, fmt2 );
    cards += summarycard( "Mean Marginal Effective Tax Rates (METRs)", 
        sum.mean_metr1, sum.mean_metr2, sum.Δmean_metr, false, pctfmt );
    cards += summarycard( "Median METRs", 
        sum.median_metr1, sum.median_metr2, sum.Δmedian_metr, false, pctfmt );
    cards += summarycard( "Mean Equivalised Household Income", 
        sum.mean_income1, sum.mean_income2, sum.Δmean_income, true, moneyfmt );
    cards += summarycard( "Median Equivalised Household Income", 
        sum.median_income1, sum.median_income2, sum.Δmedian_income, true, moneyfmt );
    cards += "</div>"
    return headline + glline + cards;
}