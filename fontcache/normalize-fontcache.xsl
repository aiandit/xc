<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fc="http://ai-and-it.de/xmlns/2020/fontcache"
  xmlns="http://ai-and-it.de/xmlns/2020/fontcache"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8" indent="yes"/>

  <xsl:key name="byfile" use="fc:file" match="fc:entry"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="text()|*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="fc:fontcache">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="fc:entry">
        <xsl:sort select="concat(fc:Family,'-',fc:Subfamily,'-',substring-after(fc:file, '.'))"
                  data-type="text" order="ascending"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="fc:Subfamily[.='Oblique']">
    <Subfamily>Italic</Subfamily>
  </xsl:template>

  <xsl:template match="fc:Subfamily[.='BoldOblique']">
    <Subfamily>BoldItalic</Subfamily>
  </xsl:template>

  <xsl:template match="fc:Subfamily[.='Book']">
    <Subfamily>Regular</Subfamily>
  </xsl:template>

  <xsl:template match="fc:Subfamily[.='Roman']">
    <Subfamily>Regular</Subfamily>
  </xsl:template>

  <xsl:template match="fc:Subfamily[.='ExtraLight']">
    <Subfamily>Regular</Subfamily>
  </xsl:template>

  <xsl:template match="fc:Subfamily[.='AllSC']">
    <Subfamily>Regular</Subfamily>
  </xsl:template>

</xsl:stylesheet>
