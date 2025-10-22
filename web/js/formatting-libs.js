
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