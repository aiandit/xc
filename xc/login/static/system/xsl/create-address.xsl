<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
  version="1.0">

  <xsl:include href="xc-utils.xsl"/>

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:variable name="template-doc-uri" select="'/main/getf/types/address.xml'"/>
  <xsl:variable name="template-doc" select="document($template-doc-uri)"/>

  <xsl:template match="/">
    <xsl:apply-templates select="$template-doc" mode="to-xc"/>
  </xsl:template>

</xsl:stylesheet>
