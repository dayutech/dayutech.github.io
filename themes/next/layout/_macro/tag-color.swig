<script type="text/javascript">
            var tagsall=document.getElementsByClassName("post-tags")
            for (var i = tagsall.length - 1; i >= 0; i--){
                var tags=tagsall[i].getElementsByTagName("a");
                for (var j = tags.length - 1; j >= 0; j--) {
                    var golden_ratio = 0.618033988749895;
                    var s = 0.5;
                    var v = 0.999;
                    var h = golden_ratio + Math.random()*0.8 - 0.5;
                    var h_i = parseInt(h * 6);
                    var f = h * 6 - h_i;
                    var p = v * (1 - s);
                    var q = v * (1 - f * s);
                    var t = v * (1 - (1 - f) * s);
                    var r, g, b;
                    switch (h_i) {
                        case 0:
                            r = v;
                            g = t;
                            b = p;
                            break;
                        case 1:
                            r = q;
                            g = v;
                            b = p;
                            break;
                        case 2:
                            r = p;
                            g = v;
                            b = t;
                            break;
                        case 3 :
                            r = p;
                            g = q;
                            b = v;
                            break;
                        case 4:
                            r = t;
                            g = p;
                            b = v;
                            break;
                        case 5:
                            r = v;
                            g = p;
                            b = q;
                            break;
                        default:
                            r = 1;
                            g = 1;
                            b = 1;
                      }
                    tags[j].style.background = "rgba("+parseInt(r*255)+","+parseInt(g*255)+","+parseInt(b*255)+","+0.5+")";
                }
            }                        
            </script>