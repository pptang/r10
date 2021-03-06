module R10.Paragraph exposing
    ( large, normal, small, xlarge, xxlarge, xsmall, xxsmall
    , normalMarkdown
    )

{-| Paraggraphs.

@docs large, normal, small, xlarge, xxlarge, xsmall, xxsmall

@docs normalMarkdown

-}

import Element exposing (..)
import R10.FontSize
import R10.Link
import R10.SimpleMarkdown
import R10.Theme


paragraphSpacing : Attribute msg
paragraphSpacing =
    spacing 10


{-| -}
normalMarkdown : List (Attribute msg) -> R10.Theme.Theme -> String -> Element msg
normalMarkdown attrs theme string =
    normal attrs
        (R10.SimpleMarkdown.elementMarkdownAdvanced
            { link = R10.Link.attrs theme }
            string
        )


{-| -}
normal : List (Attribute msg) -> List (Element msg) -> Element msg
normal attrs children =
    paragraph ([ paragraphSpacing ] ++ attrs) children


{-| -}
large : List (Attribute msg) -> List (Element msg) -> Element msg
large attrs children =
    paragraph ([ R10.FontSize.large ] ++ attrs) children


{-| -}
xlarge : List (Attribute msg) -> List (Element msg) -> Element msg
xlarge attrs children =
    paragraph ([ R10.FontSize.xlarge ] ++ attrs) children


{-| -}
xxlarge : List (Attribute msg) -> List (Element msg) -> Element msg
xxlarge attrs children =
    paragraph ([ R10.FontSize.xxlarge ] ++ attrs) children


{-| -}
small : List (Attribute msg) -> List (Element msg) -> Element msg
small attrs children =
    paragraph ([ R10.FontSize.small ] ++ attrs) children


{-| -}
xsmall : List (Attribute msg) -> List (Element msg) -> Element msg
xsmall attrs children =
    paragraph ([ R10.FontSize.xsmall ] ++ attrs) children


{-| -}
xxsmall : List (Attribute msg) -> List (Element msg) -> Element msg
xxsmall attrs children =
    paragraph ([ R10.FontSize.xsmall ] ++ attrs) children
