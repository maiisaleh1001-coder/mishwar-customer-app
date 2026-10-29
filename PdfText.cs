using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

public static class PdfText
{
    static Encoding L1 = Encoding.GetEncoding(28591);
    static Dictionary<int, string> objs = new Dictionary<int, string>();
    static Dictionary<int, string> streams = new Dictionary<int, string>();
    static Dictionary<int, Dictionary<int, string>> fontMaps = new Dictionary<int, Dictionary<int, string>>();
    static List<int> pages = new List<int>();

    static byte[] Inflate(byte[] data)
    {
        using (var ms = new MemoryStream(data, 2, data.Length - 2))
        using (var ds = new DeflateStream(ms, CompressionMode.Decompress))
        using (var o = new MemoryStream())
        {
            try { ds.CopyTo(o); } catch { }
            return o.ToArray();
        }
    }

    static string HexToStr(string h)
    {
        h = Regex.Replace(h, @"\s", "");
        var bytes = new byte[h.Length / 2];
        for (int i = 0; i < bytes.Length; i++) bytes[i] = Convert.ToByte(h.Substring(i * 2, 2), 16);
        return Encoding.BigEndianUnicode.GetString(bytes);
    }

    static Dictionary<int, string> ParseCMap(string c)
    {
        var map = new Dictionary<int, string>();
        foreach (Match blk in Regex.Matches(c, @"(?s)beginbfchar(.*?)endbfchar"))
            foreach (Match p in Regex.Matches(blk.Groups[1].Value, @"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]*)>"))
                map[Convert.ToInt32(p.Groups[1].Value, 16)] = HexToStr(p.Groups[2].Value);
        foreach (Match blk in Regex.Matches(c, @"(?s)beginbfrange(.*?)endbfrange"))
            foreach (Match p in Regex.Matches(blk.Groups[1].Value, @"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*(<[0-9A-Fa-f]*>|\[[^\]]*\])"))
            {
                int lo = Convert.ToInt32(p.Groups[1].Value, 16), hi = Convert.ToInt32(p.Groups[2].Value, 16);
                string d = p.Groups[3].Value;
                if (d.StartsWith("["))
                {
                    var arr = Regex.Matches(d, @"<([0-9A-Fa-f]*)>");
                    for (int k = 0; k <= hi - lo && k < arr.Count; k++) map[lo + k] = HexToStr(arr[k].Groups[1].Value);
                }
                else
                {
                    string s = HexToStr(d.Trim('<', '>'));
                    for (int k = 0; k <= hi - lo; k++)
                        map[lo + k] = s.Substring(0, s.Length - 1) + (char)(s[s.Length - 1] + k);
                }
            }
        return map;
    }

    static void Walk(int n)
    {
        string o = objs[n];
        if (Regex.IsMatch(o, @"/Type\s*/Pages"))
        {
            string kids = Regex.Match(o, @"/Kids\s*\[([^\]]*)\]").Groups[1].Value;
            foreach (Match k in Regex.Matches(kids, @"(\d+)\s+0\s+R")) Walk(int.Parse(k.Groups[1].Value));
        }
        else pages.Add(n);
    }

    static Dictionary<string, int> PageFonts(int pn)
    {
        string o = objs[pn];
        var rm = Regex.Match(o, @"/Resources\s+(\d+)\s+0\s+R");
        string res = rm.Success ? objs[int.Parse(rm.Groups[1].Value)] : o;
        var fm = Regex.Match(res, @"/Font\s+(\d+)\s+0\s+R");
        string fd = fm.Success ? objs[int.Parse(fm.Groups[1].Value)] : Regex.Match(res, @"(?s)/Font\s*<<(.*?)>>").Groups[1].Value;
        var h = new Dictionary<string, int>();
        foreach (Match f in Regex.Matches(fd, @"/([^\s/]+)\s+(\d+)\s+0\s+R")) h[f.Groups[1].Value] = int.Parse(f.Groups[2].Value);
        return h;
    }

    static string PageContent(int pn)
    {
        var cm = Regex.Match(objs[pn], @"/Contents\s*(\[[^\]]*\]|\d+\s+0\s+R)");
        var sb = new StringBuilder();
        foreach (Match r in Regex.Matches(cm.Groups[1].Value, @"(\d+)\s+0\s+R"))
        {
            string st; if (streams.TryGetValue(int.Parse(r.Groups[1].Value), out st)) sb.Append(st).Append('\n');
        }
        return sb.ToString();
    }

    class Run { public double x, y; public List<string> u; }

    static bool IsLtr(string t) { return Regex.IsMatch(t, @"[A-Za-z0-9٠-٩@]"); }
    static bool IsNeutral(string t) { return Regex.IsMatch(t, @"^[\s\.\-:/,%_()+#&]+$"); }

    static string ExtractPage(int pn)
    {
        var fonts = PageFonts(pn);
        string c = PageContent(pn);
        var runs = new List<Run>();
        Dictionary<int, string> cur = null;
        double x = 0, y = 0;
        double[] ctm = { 1, 0, 0, 1, 0, 0 };
        var ctmStack = new Stack<double[]>();
        var stack = new List<object>();
        List<string> arr = null; bool inArr = false;
        string tok = @"<<|>>|<[0-9A-Fa-f\s]*>|\((?:\\.|[^\\)])*\)|\[|\]|/[^\s/\[\]<>()]+|-?\d*\.?\d+|[A-Za-z'""*]+";
        foreach (Match t in Regex.Matches(c, tok))
        {
            string v = t.Value;
            if (v == "<<" || v == ">>") continue;
            if (v == "[") { inArr = true; arr = new List<string>(); continue; }
            if (v == "]") { inArr = false; stack.Add(arr); continue; }
            if (v.StartsWith("<"))
            {
                string h = Regex.Replace(v.Trim('<', '>'), @"\s", "");
                var units = new List<string>();
                for (int i = 0; i + 4 <= h.Length; i += 4)
                {
                    int g = Convert.ToInt32(h.Substring(i, 4), 16); string m;
                    if (cur != null && cur.TryGetValue(g, out m)) units.Add(m);
                }
                if (inArr) arr.AddRange(units); else stack.Add(units);
                continue;
            }
            if (inArr) continue;
            double num;
            if (v.StartsWith("/") || v.StartsWith("(") || double.TryParse(v, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out num)) { stack.Add(v); continue; }
            Func<int, double> N = k => double.Parse((string)stack[stack.Count - k], System.Globalization.CultureInfo.InvariantCulture);
            try
            {
                switch (v)
                {
                    case "q": ctmStack.Push((double[])ctm.Clone()); break;
                    case "Q": if (ctmStack.Count > 0) ctm = ctmStack.Pop(); break;
                    case "cm":
                        {
                            double a = N(6), b = N(5), cc = N(4), d = N(3), e = N(2), f = N(1);
                            ctm = new double[] { a * ctm[0] + b * ctm[2], a * ctm[1] + b * ctm[3], cc * ctm[0] + d * ctm[2], cc * ctm[1] + d * ctm[3], e * ctm[0] + f * ctm[2] + ctm[4], e * ctm[1] + f * ctm[3] + ctm[5] };
                            break;
                        }
                    case "BT": x = 0; y = 0; break;
                    case "Tf": { string fn = ((string)stack[stack.Count - 2]).TrimStart('/'); int fo; cur = fonts.TryGetValue(fn, out fo) && fontMaps.ContainsKey(fo) ? fontMaps[fo] : null; break; }
                    case "Tm": x = N(2); y = N(1); break;
                    case "Td": case "TD": x += N(2); y += N(1); break;
                    case "Tj": case "TJ":
                        {
                            var u = stack[stack.Count - 1] as List<string>;
                            if (u != null && u.Count > 0)
                                runs.Add(new Run { x = x * ctm[0] + y * ctm[2] + ctm[4], y = x * ctm[1] + y * ctm[3] + ctm[5], u = u });
                            break;
                        }
                }
            }
            catch { }
            stack.Clear();
        }
        var sbOut = new StringBuilder();
        // group by page y (PDF y grows upward -> sort descending)
        var lines = new List<List<Run>>();
        foreach (var r in runs.OrderByDescending(r => r.y))
        {
            var last = lines.Count > 0 ? lines[lines.Count - 1] : null;
            if (last != null && Math.Abs(last[0].y - r.y) < 3) last.Add(r); else lines.Add(new List<Run> { r });
        }
        foreach (var ln in lines)
        {
            var vis = new List<string>();
            foreach (var r in ln.OrderBy(r => r.x)) foreach (var u in r.u) vis.Add(u.Normalize(NormalizationForm.FormKC));
            vis.Reverse();
            var res = new List<string>(); var buf = new List<string>();
            foreach (var u in vis)
            {
                if (IsLtr(u) || (buf.Count > 0 && IsNeutral(u))) buf.Add(u);
                else
                {
                    if (buf.Count > 0)
                    {
                        // trailing neutrals belong outside the LTR run
                        var trail = new List<string>();
                        while (buf.Count > 0 && IsNeutral(buf[buf.Count - 1])) { trail.Add(buf[buf.Count - 1]); buf.RemoveAt(buf.Count - 1); }
                        buf.Reverse(); res.AddRange(buf); res.AddRange(trail); buf.Clear();
                    }
                    res.Add(u);
                }
            }
            if (buf.Count > 0) { buf.Reverse(); res.AddRange(buf); }
            string line = Regex.Replace(string.Concat(res), @"\s+", " ").Trim();
            // mirror brackets for RTL
            if (line.Length > 0) sbOut.AppendLine(line);
        }
        return sbOut.ToString();
    }

    public static string Run1(string pdf)
    {
        byte[] b = File.ReadAllBytes(pdf);
        string s = L1.GetString(b);
        foreach (Match m in Regex.Matches(s, @"(?s)(\d+) 0 obj(.*?)endobj"))
        {
            int num = int.Parse(m.Groups[1].Value); string body = m.Groups[2].Value;
            int si = body.IndexOf("stream");
            if (si >= 0)
            {
                string dict = body.Substring(0, si); objs[num] = dict;
                if (Regex.IsMatch(dict, @"/Subtype\s*/Image")) continue;
                int start = m.Groups[2].Index + si + 6;
                if (s[start] == '\r') start++; if (s[start] == '\n') start++;
                int end = m.Groups[2].Index + body.LastIndexOf("endstream");
                var raw = new byte[end - start]; Array.Copy(b, start, raw, 0, raw.Length);
                if (dict.Contains("FlateDecode")) raw = Inflate(raw);
                streams[num] = L1.GetString(raw);
            }
            else objs[num] = body;
        }
        foreach (var kv in objs)
        {
            var mm = Regex.Match(kv.Value, @"/ToUnicode\s+(\d+)\s+0\s+R");
            string cs;
            if (mm.Success && streams.TryGetValue(int.Parse(mm.Groups[1].Value), out cs)) fontMaps[kv.Key] = ParseCMap(cs);
        }
        int root = objs.Keys.First(k => Regex.IsMatch(objs[k], @"/Type\s*/Pages") && !objs[k].Contains("/Parent"));
        Walk(root);
        var sb = new StringBuilder();
        for (int p = 0; p < pages.Count; p++)
        {
            sb.AppendLine("===== Page " + (p + 1) + " =====");
            sb.Append(ExtractPage(pages[p]));
        }
        return sb.ToString();
    }
}
