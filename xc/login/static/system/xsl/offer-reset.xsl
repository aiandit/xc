<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
                version="1.0">

  <xsl:output method="xml"/>

  <xsl:include href="copy.xsl"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="x:sum-netto|x:sum-brutto|x:sum-taxes|x:cur|x:uststz|x:cost"/>

</xsl:stylesheet>
