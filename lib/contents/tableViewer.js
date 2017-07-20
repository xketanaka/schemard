
// テーブル・リレーションを格納するコンテナクラス
//
class tvFigures {
  constructor(){
    this.tables = {};
    this.relations = {};
  }
  addTable(name, tableObject){
    this.tables[name] = tableObject;
  }
  addRelation(name, relationObject){
    this.relations[name] = relationObject;
  }
  getTable(name){
    return this.tables[name];
  }
  static generateRelationName(parentTable, childTable){
    return "relation-" + parentTable + "-" + childTable;
  }
  getRelation(name){
    return this.relations[name];
  }
  getRelationsAs(as, tableName){
    return Object.values(this.relations).filter((relObj)=>{ return relObj[as].name == tableName });
  }
  getRelationsAsChild(childTableName){
    return this.getRelationsAs("child", childTableName);
  }
  getRelationsAsParent(parentTableName){
    return this.getRelationsAs("parent", parent);
  }
  overlayExceptOptions(relation){
    return { exceptTable: [relation.parent.name, relation.child.name], exceptRelation: [relation.name] };
  }
  getOverlayedRelations(){
    return Object.values(this.relations).filter((relation)=>{
      return this.isOverlayAboutLines(relation.getFigure().getLines(), this.overlayExceptOptions(relation));
    })
  }
  isNotOverlay(relationFigure, options){
    let overlay = true;
    while(overlay){
      overlay = this.isOverlayAboutLines(relationFigure.getLines(), options);
      if(!overlay) break;
      if(!relationFigure.nextOffset()) break;
    }
    if(!overlay){
      relationFigure.fixOffset();
    }
    return !overlay;
  }
  isOverlayAboutLines(lines, options){
    const MARGIN = 5; // ギリギリずれている場合に、重なっていると判定するための余白
    return Object.keys(this.tables)
    .some((tblName)=>{
      let { top, bottom, left, right } = this.tables[tblName].position;
      [ top, bottom, left, right ] = [ top + 1, bottom - 1, left + 1, right - 1 ];

      return lines.some((line)=>{ return line.isOverlay(top, bottom, left, right) })

    }) || Object.keys(this.tables).filter((tblName => !options.exceptTable.includes(tblName)))
    .some((tblName)=>{
      let { top, bottom, left, right } = this.tables[tblName].position;
      [ top, bottom, left, right ] = [ top - MARGIN, bottom + MARGIN, left - MARGIN, right + MARGIN ];

      return lines.some((line)=>{ return line.isOverlay(top, bottom, left, right) })

    }) || Object.keys(this.relations).filter(relName => !options.exceptRelation.includes(relName))
    .some((relName)=>{
      let relationLines = this.relations[relName].getFigure().getLines();
      return lines.some((line)=>{
        return relationLines.some((relationLine)=>{
          if(line.isVertical == relationLine.isVertical){
            // 平行な線
            return line.fixedPosition == relationLine.fixedPosition
              && line.start - MARGIN < relationLine.end && relationLine.start < line.end + MARGIN;
          }else{
            // 交差する線
            return relationLine.start < line.fixedPosition && line.fixedPosition < relationLine.end
              && line.start - MARGIN < relationLine.fixedPosition && relationLine.fixedPosition < line.end + MARGIN;
          }
        })
      })
    })
  }
}

var figures = new tvFigures();

// 線 を表すクラス
//
class tvLine {
  constructor(direction, fixedPosition){
    this.isVertical = (direction == "vertical");
    this.fixedPosition = fixedPosition;
  }
  setStartEnd(start, end){
    this.start = parseFloat(start < end ? start : end);
    this.end = parseFloat(start < end ? end : start);
    return this;
  }
  getPointOf(startOrEnd){
    if(this.isVertical){
      return { left: this.fixedPosition, top: this[startOrEnd] };
    }else{
      return { left: this[startOrEnd], top: this.fixedPosition };
    }
  }
  get startPoint(){ return this.getPointOf("start") }
  get endPoint(){ return this.getPointOf("end") }
  get centerPoint(){
    let fixed = this.fixedPosition, center =  (this.start + this.end)/2;
    return this.isVertical ? { left: fixed, top: center } :  { left: center, top: fixed };
  }
  length(){ return Math.abs(this.start - this.end) }

  pointsOnLine(){
    if(this.points) return this.points;

    let [fixed, moving] = this.isVertical ? ["left", "top"]: ["top", "left"];

    let center = (this.start + this.end) / 2;
    this.points = [ { [fixed]: this.fixedPosition, [moving]: center } ];

    // 前後 20px ずつずらしていく。ただし両端 20px は空けておく
    for(let offset = 20; center - (offset + 20) > this.start; offset += 20){
      this.points.push({ [fixed]: this.fixedPosition, [moving]: center - offset });
      this.points.push({ [fixed]: this.fixedPosition, [moving]: center + offset });
    }
    return this.points;
  }
  isOverlay(top, bottom, left, right){
    let [fixedMin, fixedMax] = this.isVertical ? [left, right] : [top, bottom];
    let [startEndMin, startEndMax] = this.isVertical ? [top, bottom] : [left, right];
    if(this.fixedPosition < fixedMin || fixedMax < this.fixedPosition) return false;
    if(this.end < startEndMin || startEndMax < this.start) return false;
    return true;
  }
}
class tvVerticalLine extends tvLine {
  constructor(fixedPosition){
    super("vertical", fixedPosition)
  }
}
class tvHorizontalLine extends tvLine {
  constructor(fixedPosition){
    super("horizontal", fixedPosition)
  }
}
// テーブルの枠線 を表すクラス(sideプロパティで四辺のいずれか(top,right,bottom,left)を識別する)
//
class tvTableLine extends tvLine {
  constructor(tableName, side, fixedPosition){
    super((side=="top"||side=="bottom")? "horizontal" : "vertical", fixedPosition)
    this.tableName = tableName;
    this.side = side;
  }
  searchBindPoint(anotherLine){
    if(!this.points){
      this.points = this.pointsOnLine();
      this.boundPoints = new Set();
    }
    this.temporaryBound = [];
    return this.nextBindPoint(anotherLine);
  }
  nextBindPoint(anotherLine){
    let topOrLeft = this.isVertical ? "top" : "left";
    let centerPosition = this.centerPoint[topOrLeft];
    // anotherLine が指定されている場合は、検索方向を固定する(中央から端まで)
    let nextDirection;
    if(anotherLine){
      nextDirection = { centerToEnd: centerPosition < anotherLine.centerPoint[topOrLeft] };
      nextDirection.centerToStart = !nextDirection.centerToEnd;
    }
    for(let i=0; i < this.points.length; i++){
      // 検索方向が指定されている場合
      if(nextDirection){
        if(nextDirection.centerToEnd && centerPosition > this.points[i][topOrLeft]) continue;
        if(nextDirection.centerToStart && centerPosition < this.points[i][topOrLeft]) continue;
      }
      if(this.boundPoints.has(i)) continue;
      if(this.temporaryBound.includes(i)) continue;

      this.temporaryBound.push(i);
      return this.points[i];
    }
    // anotherLineの指定なしで呼び出す
    if(anotherLine){
      return this.nextBindPoint();
    }
    // それでも見つからない場合は undefined
  }
  // temporaryBound を確定する
  fixBindPoint(){
    if(this.temporaryBound.length > 0){
      this.boundPoints.add(this.temporaryBound[this.temporaryBound.length - 1]);
    }
  }
  // boundPoints を解除する
  unbind(point){
    for(let i of this.boundPoints){
      if(this.points[i].left == point.left && this.points[i].top == point.top){
        this.boundPoints.delete(i);
      }
    }
  }
}

// テーブル を表すクラス
//
class tvTable {
  constructor(name, left, top, width, height){
    this.name = name;
    this.width = parseFloat(width);
    this.height = parseFloat(height);
    this.moveTo(parseFloat(left), parseFloat(top));
  }
  moveTo(left, top){
    this.left = parseFloat(left);
    this.top = parseFloat(top);
    this.center = { left: this.left + this.width/2, top: this.top + this.height/2 };
    this.position = {
      left: this.left, right: this.left + this.width,
      top:  this.top,  bottom: this.top + this.height,
    };
    this.sideLines = {}; // clear
  }
  getLineOf(side){
    if(this.sideLines[side]) return this.sideLines[side];

    this.sideLines[side] = new tvTableLine(this.name, side, this.position[side])
    if(side=="top" || side=="bottom"){
      this.sideLines[side].setStartEnd(this.position.left, this.position.right);
    }else{
      this.sideLines[side].setStartEnd(this.position.top, this.position.bottom);
    }
    return this.sideLines[side];
  }
  // "top", "bottom", "left", "right" のいずれかを返す
  getSideOf(line){
    if(line.isVertical){
      return line.fixedPosition == this.position.left ? "left" : "right"
    }else{
      return line.fixedPosition == this.position.top ? "top" : "bottom"
    }
  }
  getVerticalLines(){
    return [ this.getLineOf("left"), this.getLineOf("right") ];
  }
  getHorizontalLines(){
    return [ this.getLineOf("top"), this.getLineOf("bottom") ];
  }
  // 指定されたテーブル側の辺（１つか２つ）を返す
  nearlySideLines(otherTable){
    let otherPosition = otherTable.position;
    let lines = [];
    if(this.position.top > otherPosition.bottom) lines.push(this.getLineOf("top"));
    if(this.position.bottom < otherPosition.top) lines.push(this.getLineOf("bottom"));
    if(this.position.left > otherPosition.right) lines.push(this.getLineOf("left"));
    if(this.position.right < otherPosition.left) lines.push(this.getLineOf("right"));
    return lines;
  }
  // 指定されたテーブルの中央の距離のうち、近い方を返す。
  // ただし、２つのテーブルの垂直位置が少しでも重なる場合は、水平距離は返さない（垂直距離を返す）
  // また、２つのテーブルの水平位置が少しでも重なる場合は、垂直距離は返さない（水平距離を返す）
  nearlyCenterPositionDistance(otherTable){
    let distances = {
      left: Math.abs(this.center.left - otherTable.center.left),
      top: Math.abs(this.center.top - otherTable.center.top),
    };
    if(this.position.top < otherTable.position.bottom && this.position.bottom > otherTable.position.top)
      return distances.top;
    if(this.position.left < otherTable.position.right && this.position.right > otherTable.position.left)
      return distances.left;
    else
      return Object.values(distances).sort((a, b)=> a - b)[0];
  }
  static create(name, options){
    let table = new tvTable(name, options.left, options.top, options.width, options.height);
    figures.addTable(name, table);
    return table;
  }
}

// リレーションを表すクラス
//
class tvRelation {
  constructor(name, parentTbl, childTbl, childCardinality){
    this.name = name;
    this.parent = parentTbl;
    this.child  = childTbl;
    this.childCardinality = childCardinality;
  }
  unbind(){
    this.parentSideLine && this.parentSideLine.unbind(this.parentPoint);
    this.childSideLine && this.childSideLine.unbind(this.childPoint);
    delete this.relationFigure;
  }
  calcLinePosition(){
    this.unbind();
    // 選択された辺により折れ線の種類・始点/終点を決定
    let parentLines = this.parent.nearlySideLines(this.child);
    let childLines = this.child.nearlySideLines(this.parent);

    let TOO_NEAR_LIMIT = 30;

    if(parentLines.length == 2){

      // 中央位置より優先する辺(方向:垂直/水平)を選択
      let isPriorVertical = false;
      if(Math.abs(this.parent.center.left - this.child.center.left)
         > Math.abs(this.parent.center.top - this.child.center.top)){
        isPriorVertical = true;
      }
      let paLine = parentLines.find(v => v.isVertical === isPriorVertical);
      let chLine = childLines.find(v => v.isVertical === isPriorVertical);

      /// 平行線が近すぎず、かつ点が見つかれば処理終了
      if(Math.abs(paLine.fixedPosition - chLine.fixedPosition) > TOO_NEAR_LIMIT){
        if(this.searchPoint(paLine, chLine)) return true;
      }
      // parentLines のもう片方を選択
      let altPaLine = parentLines.find(v => v.isVertical !== isPriorVertical);
      let altChLine = childLines.find(v => v.isVertical !== isPriorVertical);
      /// 平行線が近すぎず、かつ点が見つかれば処理終了
      if(altChLine && Math.abs(altPaLine.fixedPosition - altChLine.fixedPosition) > TOO_NEAR_LIMIT){
        if(this.searchPoint(altPaLine, altChLine)) return true;
      }
      // それでも点が見つからない場合、交差する組み合わせを試す
      if(this.searchPoint(paLine, altChLine)) return true;
      if(this.searchPoint(altPaLine, chLine)) return true;

    }else if(parentLines.length == 1){
      /// 一組しか線が選択されなかった場合、平行線が近すぎず、かつ点が見つかれば処理終了
      if(Math.abs(parentLines[0].fixedPosition - childLines[0].fixedPosition) > TOO_NEAR_LIMIT){
        if(this.searchPoint(parentLines[0], childLines[0])) return true;
      }

    }else{
      // テーブル同士が重なっている場合, とりあえずtop同士でつなぐ
      return this.searchPoint(this.parent.getLineOf("top"), this.child.getLineOf("top"), true);
    }

    // 選択すべき点がない場合、平行でない辺を選択
    let paLine = parentLines[0];
    let chLine = childLines[0];
    let otherDirection = paLine.isVertical ? "Horizontal": "Vertical";

    // まず長さが短い方の辺を, 平行でない辺に変更
    if(paLine.length() < chLine.length()){
      paLine = this.selectOtherSideLineFor("parent", otherDirection);
    }else{
      chLine = this.selectOtherSideLineFor("child", otherDirection);
    }
    // 点が見つかれば処理終了
    if(paLine && chLine && this.searchPoint(paLine, chLine)) return true;

    // それでも見つからなければ長さが長い方の辺を変更(長い方の辺は取得できない場合がある)
    if(paLine.length() >= chLine.length()){
      paLine = this.selectOtherSideLineFor("parent", otherDirection);
    }else{
      chLine = this.selectOtherSideLineFor("child", otherDirection);
    }
    // 点が見つかれば処理終了
    if(paLine && chLine && this.searchPoint(paLine, chLine)) return true;

    // それでも見つからない場合は 0 番目のLineで決定とする
    return this.searchPoint(parentLines[0], childLines[0], true);
  }
  // targetTable の direction (=Vertical or Horizontal) の辺を取得する
  selectOtherSideLineFor(targetTable, direction){
    let nonTargetTable = targetTable == "parent" ? "child" : "parent";

    let targetLines = this[targetTable][`get${direction}Lines`]();
    let nonTargetLines = this[nonTargetTable][`get${direction}Lines`]();

    if(targetLines[0].fixedPosition < nonTargetLines[1].fixedPosition
       && targetLines[1].fixedPosition > nonTargetLines[0].fixedPosition){
      // 重なっている場合, nonTargetLines[0] と nonTargetLines[1] の間にある辺を返す
      return targetLines.find((line)=>{
        return nonTargetLines[0].fixedPosition <= line.fixedPosition
               && line.fixedPosition <= nonTargetLines[1].fixedPosition;
      });
    }else{
      // 重なってない場合, nonTargetLine[0] に近い方の辺を返す
      return targetLines[targetLines[0].fixedPosition > nonTargetLines[0].fixedPosition ? 0 : 1];
    }
  }
  // 線を引き、他の何かを重なってないか判定
  // 重なっていれば、点を選択しなおす(選択すべき点がなければfalseを返す)
  searchPoint(paLine, chLine, noSearch = false){
    // 選択された辺により折れ線の種類・始点/終点を決定
    this.parentSideLine = paLine;
    this.childSideLine = chLine;
    this.parentPoint = paLine.searchBindPoint(chLine);
    this.childPoint = chLine.searchBindPoint(paLine);

    let found = noSearch;
    let relationFigure = noSearch && this.getFigure();

//DEBUG if(noSearch) console.log("noSearch!!!!!!!!!!!! " + this.name);

    while(!found){
      if(!this.parentPoint || !this.childPoint) break;
      if(found = figures.isNotOverlay(relationFigure = this.getFigure(), figures.overlayExceptOptions(this))) break;

      this.parentPoint = paLine.nextBindPoint(chLine);

      if(!this.parentPoint) break;
      if(found = figures.isNotOverlay(relationFigure = this.getFigure(), figures.overlayExceptOptions(this))) break;

      this.childPoint = chLine.nextBindPoint(paLine);
    }
    if(found){
      this.parentSideLine.fixBindPoint();
      this.childSideLine.fixBindPoint();
      this.fixFigure(relationFigure.fixOffset());
    }
    return found;
  }
  fixFigure(figure){
    this.relationFigure = figure;
  }
  getFigure(){
    if(this.relationFigure) return this.relationFigure;

    // Parent, Child が完全に重なっている場合など、this.parentPoint, this.childPointが undefined になっている。
    // とりあえず中央点にする
    this.parentPoint = this.parentPoint || this.parentSideLine.centerPoint;
    this.childPoint = this.childPoint || this.childSideLine.centerPoint

    if(this.parentSideLine.isVertical == this.childSideLine.isVertical){
      /////  └┐,  ┌┘, │ のいずれか
      let prop = this.parentSideLine.isVertical ? "top" : "left";

      if(this.parentPoint[prop] == this.childPoint[prop]){
        return new tvRelationFigure1(this.parentPoint, this.childPoint)
      }else{
        return new tvRelationFigure3(this.parentPoint, this.childPoint, ! this.parentSideLine.isVertical)
      }
    }else{
      /////  └, ┘, ┌, ┐ のいずれか
      // 上にある方を posA、下にある方を posB とする
      let [posA, posB] = [this.parentPoint, this.childPoint]
      if(this.parentPoint.top > this.childPoint.top){
        [posA, posB] = [posB, posA];
      }
      let posASideLine = this.parentPoint.top < this.childPoint.top ? this.parentSideLine : this.childSideLine;
      if(posASideLine.isVertical){
        // ┌, ┐ のいずれか
        return new tvRelationFigure2(posA, posB, { top: posA.top, left: posB.left });
      }else{
        // └, ┘ のいずれか
        return new tvRelationFigure2(posA, posB, { top: posB.top, left: posA.left });
      }
    }
  }
  get parentEdge(){
    if(!this.parentSideLine || !this.parentPoint) return;
    return { point: this.parentPoint, side: this.parent.getSideOf(this.parentSideLine) };
  }
  get childEdge(){
    if(!this.childSideLine || !this.childPoint) return;
    return { point: this.childPoint, side: this.child.getSideOf(this.childSideLine), cardinality: this.childCardinality };
  }
  static create(name, parentTbl, childTbl, childCardinality){
    let relation = new tvRelation(name, parentTbl, childTbl, childCardinality);
    figures.addRelation(name, relation);
    return relation;
  }
}

// 直線図形のリレーション
class tvRelationFigure1 {
  constructor(posA, posB){
    if(posA.left == posB.left){
      this.line = new tvLine("vertical", posA.left).setStartEnd(posA.top, posB.top)
    }else{
      this.line = new tvLine("horizontal", posA.top).setStartEnd(posA.left, posB.left)
    }
  }
  getLines(){
    return [ this.line ];
  }
  nextOffset(){ return false }
  fixOffset(){ return this }
  displayInfo(){
    return [ this.line.isVertical ?
      { top: this.line.start, left: this.line.fixedPosition, width: 10, height: this.line.length(), borders: ["left"] } :
      { top: this.line.fixedPosition, left: this.line.start, width: this.line.length(), height: 10, borders: ["top"] }
    ];
  }
}
// 折線(角1つ)図形のリレーション
class tvRelationFigure2 {
  constructor(posA, posB, corner){
    this.lines = [];
    if(posA.top == corner.top){
      this.lines.push(new tvHorizontalLine(posA.top).setStartEnd(posA.left, corner.left))
      this.lines.push(new tvVerticalLine(posB.left).setStartEnd(posB.top, corner.top))
    }else{
      this.lines.push(new tvVerticalLine(posA.left).setStartEnd(posA.top, corner.top))
      this.lines.push(new tvHorizontalLine(posB.top).setStartEnd(posB.left, corner.left))
    }
  }
  getLines(){
    return this.lines;
  }
  nextOffset(){ return false }
  fixOffset(){ return this }
  displayInfo(){
    let [vline, hline] = this.lines[0].isVertical ? this.lines : this.lines.concat().reverse();
    let borders = [];
    borders.push(vline.fixedPosition == hline.start ? "left" : "right")
    borders.push(hline.fixedPosition == vline.start ? "top" : "bottom")
    return [{
      top: vline.start, left: hline.start, width: hline.length(), height: vline.length(), borders: borders
    }];
  }
}
// 折線(角2つ)図形のリレーション
class tvRelationFigure3 {
  constructor(posA, posB, isVertical){
    this.isVertical = isVertical;
    this.offset = 0;
    if(isVertical){
      // 上にある方を start とする
      [this.start, this.end] = posA.top < posB.top ? [posA, posB] : [posB, posA];
    }else{
      // 左にある方を start とする
      [this.start, this.end] = posA.left < posB.left ? [posA, posB] : [posB, posA];
    }
  }
  get center(){
    let prop = this.isVertical ? "top" : "left";
    return parseInt((this.start[prop] + this.end[prop]) / 2) + this.offset;
  }
  getLines(){
    if(this.lines) return this.lines;
    let lines = [];
    if(this.isVertical){
      lines.push(new tvVerticalLine(this.start.left).setStartEnd(this.start.top, this.center));
      lines.push(new tvHorizontalLine(this.center).setStartEnd(this.start.left, this.end.left));
      lines.push(new tvVerticalLine(this.end.left).setStartEnd(this.center, this.end.top));
    }else{
      lines.push(new tvHorizontalLine(this.start.top).setStartEnd(this.start.left, this.center));
      lines.push(new tvVerticalLine(this.center).setStartEnd(this.start.top, this.end.top));
      lines.push(new tvHorizontalLine(this.end.top).setStartEnd(this.center, this.end.left));
    }
    return lines;
  }
  // 折れ線の位置を 0, 10, -10, 20, -20,, とずらしていく
  // 終端まで到達した場合は、false を返す
  nextOffset(){
    let newOffset = this.offset <= 0 ? Math.abs(this.offset) + 10 : this.offset * -1;

    let prop = this.isVertical ? "top" : "left";
    let centerLinePosition = parseInt((this.start[prop] + this.end[prop]) / 2) + newOffset;

    if(this.start[prop] < centerLinePosition - 15 && centerLinePosition + 15 < this.end[prop]){
      this.offset = newOffset;
      return true;
    }
    return false;
  }
  fixOffset(){
    this.lines = this.getLines();
    return this;
  }
  displayInfo(){
    function toggle(dir){ return { left: "right", right: "left", top: "bottom", bottom: "top" }[dir] }
    if(this.isVertical){
      // └┐,  ┌┘ のどちらか
      let [vline, hline, vline2] = this.lines;
      let borders = [ vline.fixedPosition == hline.start ? "left" : "right", "bottom" ];
      let base = { left: hline.start, width: hline.length() };
      return [
        Object.assign(Object.create(base), { top: vline.start, height: vline.length(), borders: borders }),
        Object.assign(Object.create(base), { top: vline2.start, height: vline2.length(), borders: [ toggle(borders[0]) ] })
      ];
    }else{
      // ┌  ┐
      // ┘, └  のいずれか
      let [hline, vline, hline2] = this.lines;
      let borders = [ hline.fixedPosition == vline.start ? "top" : "bottom", "right" ];
      let base = { top: vline.start, height: vline.length() };
      return [
        Object.assign(Object.create(base), { left: hline.start, width: hline.length(), borders: borders }),
        Object.assign(Object.create(base), { left: hline2.start, width: hline2.length(), borders: [ toggle(borders[0]) ] })
      ];
    }
  }
}
var Custom = {

  apply: function(){
    $('.table').bind('moved', Custom.saveTablePosition);
    $('.table .title').on('click.table_show', Custom.moveToShowPage);
    $('.editable input').bind('click', Custom.setEditMode);
  },

  initLayout: function(){
    $(".table").each(function(){

      if(!$(this).attr("data-pos-left")) $(this).attr("data-pos-left", 100)
      if(!$(this).attr("data-pos-top")) $(this).attr("data-pos-top", 100)

      $(this).css({
        "width": $(this).width() + 20,
        "left": ($(this).attr("data-pos-left") || 100)+ "px",
        "top": ($(this).attr("data-pos-top") || 100) + "px"
      });

      tvTable.create($(this).attr("data-table-name"), {
          left: $(this).attr("data-pos-left"), top: $(this).attr("data-pos-top"),
          width: parseInt($(this).outerWidth(true)), height: parseInt($(this).outerHeight(true))
      });
    });
    $(".table")
    .filter(function(){ return $(this).attr("data-relation-to") })
    .sort((tblA, tblB)=>{
      return $(tblB).attr("data-relation-to").split(",").length
        - $(tblA).attr("data-relation-to").split(",").length
    })
    .each(function(){ Custom.private.refreshRelationLines($(this)) });

    // 描画順によって重なってしまう場合があるため、重複している線について再描画を試みる
    figures.getOverlayedRelations().forEach((relation)=>{
      Custom.private.drawRelationLines(relation.name, relation);
    });

    $("a[data-link-url]").each(function(){
      if($(this).attr("href")) return;
      $(this).attr("href", Custom.URLSuffix($(this).attr("data-link-url")));
    });
  },

  saveTablePosition: function(e){
    var position = $(this).offset().left+","+$(this).offset().top;
    $.ajax({
      type: 'POST',
      url: "/tables/" + $(this).attr("data-table-name"),
      data: { layout: position }
    })
    .done(function( data, textStatus, jqXHR ) {
      // message.
    })
  },

  moveToShowPage: function(e){
    window.location.href =
      Custom.URLSuffix("tables/" + $(this).parent().attr("data-table-name"));
  },

  URLSuffix: function(url){
    var suffix = /.+\.html/.test(window.location.href)? ".html": "";
    return url == "/" && suffix == ".html" ? "./..": url + suffix;
  },

  setEditMode: function(){
    if($(this).is(':checked')){
      Custom.dragable(".table");
      $(".table").addClass("editing");
      $('.table .title').off('click.table_show');
    }else{
      Custom.unDragable(".table");
      $(".table").removeClass("editing");
      $('.table .title').on('click.table_show', Custom.moveToShowPage);
    }
  },

  unDragable: function(cssSelector){
    $(document).off('mousedown.draggable', cssSelector);
    $(document).off('mouseup.draggable');
    $(document).off('mousemove.draggable');
  },

  dragable: function(cssSelector){
    $(document).on('mousedown.draggable', cssSelector, function(e){
        $(document).data("drag-target", this);
        $(this).data("dragStartX", e.pageX);
        $(this).data("dragStartY", e.pageY);
        $(this).data("startLeft", $(this).offset().left);
        $(this).data("startTop", $(this).offset().top);
    });

    $(document).on('mouseup.draggable', function(e){
      var target = $(document).data("drag-target");
      if(target){
        Custom.private.moveTo($($(target).data("drag-target")), e);
      }
      $(document).data("drag-target", false);
      $(target).trigger("moved");
    });
    $(document).on('mousemove.draggable', function(e){
      if($(document).data("drag-target")){
        Custom.private.moveTo($($(document).data("drag-target")), e);
      }
    });
  },

  private: {

    moveTo: function($obj, e){
      var startX = $obj.data("dragStartX");
      var startY = $obj.data("dragStartY");
      if(!startX || !startY)
        return;

      $obj.css({
        "left": $obj.data("startLeft") + (e.pageX - startX),
        "top": $obj.data("startTop") + (e.pageY - startY)
      });
      figures.getTable($obj.attr("data-table-name")).moveTo(
        $obj.data("startLeft") + (e.pageX - startX), $obj.data("startTop") + (e.pageY - startY)
      )
      // 親テーブルとしての関連を再描画
      Custom.private.refreshRelationLines($obj);
      // 子テーブルとしての関連を再描画
      figures.getRelationsAsChild($obj.attr("data-table-name")).forEach((relObj)=>{
        Custom.private.refreshRelationLines($(`.table[data-table-name=${relObj.parent.name}]`));
      })
      // 親テーブルとして関連しているテーブルを再描画
      figures.getRelationsAsParent($obj.attr("data-table-name")).forEach((relObj)=>{
        Custom.private.refreshRelationLines($(`.table[data-table-name=${relObj.child.name}]`));
      })
    },

    refreshRelationLines: function($obj){
      let tableObject = figures.getTable($obj.attr("data-table-name"));
      // 関連テーブルを取得
      let relationTableObjects = $obj.attr("data-relation-to").split(",")
        .filter(v => v).map(rel => figures.getTable(rel));

      let relationCardinalities = $obj.attr("data-relation-cardinality").split(",")
        .reduce((sum, cardinality)=>{
          sum[cardinality.split(":")[0]] = cardinality.split(":")[1];
          return sum;
        }, {});

      // 関連テーブルを中心の絶対座長(X or Y)の差異が小さい順でソート
      relationTableObjects.sort((relTblA, relTblB)=>{
        return relTblA.nearlyCenterPositionDistance(tableObject)
          - relTblB.nearlyCenterPositionDistance(tableObject)
      })
      .forEach((relTable, index)=>{
        var relName = tvFigures.generateRelationName(tableObject.name, relTable.name);
        if($(`#${relName}`).length == 0){
          $("body").append("<div id=" + relName + " class='relation-line' ></div>")
        }
        let relation = figures.getRelation(relName) ||
          tvRelation.create(relName, tableObject, relTable, relationCardinalities[relTable.name]);
        Custom.private.drawRelationLines(`#${relName}`, relation);
      })
    },
    drawRelationLines: function(relId, relation){
      relation.calcLinePosition();

      let displayInfo = relation.getFigure().displayInfo();
      // └┐,  ┌┘ のように２つの角をもつ線の場合
      if(displayInfo.length == 2){
        if($(relId).children().length == 0){
          $(relId).append("<div class=\"child-1\"></div><div class=\"child-2\"></div>");
        }
        $(relId).css({ top: displayInfo[0].top, left: displayInfo[0].left, border: "none" });
        $(relId).find(".child-1").css({ top: 0, left: 0, width: displayInfo[0].width, height: displayInfo[0].height });
        ["top", "bottom", "left", "right"].forEach((border)=>{
          $(relId).find(".child-1").css(`border-${border}`, displayInfo[0].borders.includes(border) ? "solid 1px black" : "none");
        });
        $(relId).find(".child-2").css({ width: displayInfo[1].width, height: displayInfo[1].height });
        $(relId).find(".child-2").css({
          left: displayInfo[1].left - displayInfo[0].left, top: displayInfo[1].top - displayInfo[0].top
        });
        ["top", "bottom", "left", "right"].forEach((border)=>{
          $(relId).find(".child-2").css(`border-${border}`, displayInfo[1].borders.includes(border) ? "solid 1px black" : "none");
        });

      }else{
        // ┌, ┘, |, のように１ or ０個の角をもつ線の場合
        if($(relId).children().length > 0){
          $(relId).empty();
        }
        $(relId).css(displayInfo[0]);
        ["top", "bottom", "left", "right"].forEach((border)=>{
          $(relId).css(`border-${border}`, displayInfo[0].borders.includes(border) ? "solid 1px black" : "none");
        })
      }
      // 親側の記号を描画
      Custom.private.drawRelationEdge_1(`${relId}-parent-edge`, relation.parentEdge);
      // 子側の記号を描画
      if(relation.childCardinality == "1"){
        Custom.private.drawRelationEdge_1(`${relId}-child-edge`, relation.childEdge);
      }else{
        Custom.private.drawRelationEdge_N(`${relId}-child-edge`, relation.childEdge);
      }
    },
    drawRelationEdge_1: function(edgeId, edge){
      let { top: offsetTop, left: offsetLeft } = {
        top:    { top: -5, left: -5 }, bottom: { top:  0, left: -5 },
        left:   { top: -5, left: -5 }, right:  { top: -5, left:  0 }
      }[edge.side];

      if($(edgeId).length == 0){
        $("body").append("<div id='" + edgeId.substring(1) + "' class='relation-edge' ></div>");
      }
      $(edgeId).css({ top: edge.point.top + offsetTop, left: edge.point.left + offsetLeft });
      $(edgeId).css(
        ["left", "right"].includes(edge.side) ? { width: 3, height: 10 } : { width: 10, height: 3 });

      ["top", "bottom", "left", "right"].forEach((border)=>{
        $(edgeId).css(`border-${border}`, edge.side == border ? "solid 1px black" : "none");
      })
    },
    drawRelationEdge_N: function(edgeId, edge){
      let offsets = {
        top:    [{ left: -6 }, { top:  -9, left: 1 }, { left:  7 }],
        bottom: [{ left: -5, top: -1 }, { top:   7 }, { left:  5, top: -1 }],
        left:   [{ top:  -6 }, { left: -8, top: -1 }, { top:   4 }],
        right:  [{ top:  -6 }, { left:  8, top: -1 }, { top:   4 }],
      }[edge.side];

      let points = offsets.map((offset)=>{
        let point = Object.assign({}, edge.point);
        if("top" in offset) Object.assign(point, { top: offset.top + edge.point.top });
        if("left" in offset) Object.assign(point, { left: offset.left + edge.point.left });
        return point;
      });

      if($(`${edgeId}-1`).length == 0){
        $("body").append("<div id='" + edgeId.substring(1) + "-1' class='relation-edge-diagonal' ></div>")
        $("body").append("<div id='" + edgeId.substring(1) + "-2' class='relation-edge-diagonal' ></div>")
      }

      let drawDiagonalLine = (rectId, p1, p2)=>{
        let pos = p1.left < p2.left? p1: p2;
        let width = Math.abs(p1.left - p2.left);
        let height = Math.abs(p1.top - p2.top);
        let isUpToDown = ((p1.top - p2.top) * (p1.left - p2.left) < 0);

        var deg = Math.atan(height / width) / (Math.PI / 180) * (isUpToDown ? -1: 1);

        $(rectId).css({
          top: pos.top,
          left: pos.left,
          width: Math.sqrt((width * width) + (height * height)),
          height: 1,
          transform: "rotate(" + deg + "deg)",
          "transform-origin": "left top"
        });
      };
      drawDiagonalLine(`${edgeId}-1`, points[0], points[1]);
      drawDiagonalLine(`${edgeId}-2`, points[1], points[2]);
    },
  }
}

$(document).ready(Custom.initLayout);
$(document).ready(Custom.apply);
