// Logical-pixel geometry shared by the preview, drag surface, and tests.
// Edge/center snapping follows the approach used by GNOME's display panel.
function overlap(a, b) {
    return a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height;
}
function adjacent(a, b) {
    return ((a.x + a.width === b.x || b.x + b.width === a.x) && Math.min(a.y+a.height,b.y+b.height) > Math.max(a.y,b.y))
        || ((a.y + a.height === b.y || b.y + b.height === a.y) && Math.min(a.x+a.width,b.x+b.width) > Math.max(a.x,b.x));
}
function connected(rects) {
    if (!rects.length) return false;
    const seen = [0];
    for (let j = 0; j < seen.length; ++j)
        for (let i = 0; i < rects.length; ++i)
            if (seen.indexOf(i) < 0 && adjacent(rects[seen[j]], rects[i])) seen.push(i);
    return seen.length === rects.length;
}
function valid(rects) {
    return connected(rects) && rects.every((a,i) => rects.every((b,j) => i === j || !overlap(a,b)));
}
function bounds(rects) {
    if (!rects.length) return {x:0,y:0,width:1,height:1};
    const x = Math.min.apply(null,rects.map(r=>r.x)), y = Math.min.apply(null,rects.map(r=>r.y));
    return {x:x,y:y,width:Math.max.apply(null,rects.map(r=>r.x+r.width))-x,height:Math.max.apply(null,rects.map(r=>r.y+r.height))-y};
}
function fit(rects, width, height, padding, maxWidth) {
    const b = bounds(rects);
    const largest = Math.max.apply(null,rects.map(r=>r.width).concat([1]));
    const scale = Math.min((width-2*padding)/b.width,(height-2*padding)/b.height,maxWidth/largest);
    return {scale:scale,x:(width-b.width*scale)/2-b.x*scale,y:(height-b.height*scale)/2-b.y*scale};
}
function snap(rects, index, x, y, threshold) {
    const moving = rects[index], candidates = [];
    function near(value, alignments) {
        const closest = alignments.slice().sort((a,b)=>Math.abs(a-value)-Math.abs(b-value))[0];
        return Math.abs(closest-value) < threshold ? closest : value;
    }
    for (let i=0;i<rects.length;++i) {
        if (i===index) continue;
        const b=rects[i], w=moving.width, h=moving.height;
        // Keep a usable shared edge; corner-only contact cannot pass the cursor.
        const edge = Math.min(32,w,h,b.width,b.height);
        const yy = Math.max(b.y-h+edge,Math.min(y,b.y+b.height-edge));
        const xx = Math.max(b.x-w+edge,Math.min(x,b.x+b.width-edge));
        const sy = near(yy,[b.y,b.y+b.height-h,b.y+(b.height-h)/2]);
        const sx = near(xx,[b.x,b.x+b.width-w,b.x+(b.width-w)/2]);
        candidates.push({x:b.x-w,y:sy},{x:b.x+b.width,y:sy},{x:sx,y:b.y-h},{x:sx,y:b.y+b.height});
    }
    let best=null, distance=Infinity;
    for (const c of candidates) {
        c.x=Math.round(c.x); c.y=Math.round(c.y);
        const candidate=Object.assign({},moving,c);
        if (rects.some((r,i)=>i!==index && overlap(candidate,r))) continue;
        // Disconnected drafts can be joined one monitor at a time; Done still
        // requires a connected layout.
        if (!rects.some((r,i)=>i!==index && adjacent(candidate,r))) continue;
        const d=(c.x-x)*(c.x-x)+(c.y-y)*(c.y-y);
        if (d<distance) {best=candidate;distance=d;}
    }
    return best || moving;
}
