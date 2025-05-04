if (!forExport) {
    mdHtml = mdHtml.replace(
        // match any <math ...> ... </math>
        /(<math\b[^>]*>)([\s\S]*?)(<\/math>)/gi,
        (fullMatch, openMathTag, mathInner, closeMathTag) => {
            // 1. conditionally prepend <br /> if display="block" is present
            let blockPresent = /\bdisplay="block"/i.test(openMathTag);
            let out = blockPresent
                ? '<br />' + openMathTag
                : openMathTag;

            // 2. strip <mrow>…</mrow> only inside <semantics>
            out += mathInner.replace(
                /(<semantics\b[^>]*>)([\s\S]*?)(<\/semantics>)/gi,
                (semiMatch, openSemi, semiInner, closeSemi) => {
                    const cleaned = semiInner.replace(
                        /<mrow\b[^>]*>[\s\S]*?<\/mrow>/gi,
                        ''
                    );
                    return openSemi + cleaned + closeSemi;
                }
            );

            out += blockPresent
                ? closeMathTag + <br />
                : closeMathTag;

            return out;
        }
    );
}