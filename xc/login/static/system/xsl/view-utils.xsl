<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:include href="xc-utils.xsl"/>

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:template match="*">
    <xsl:param name="pos" select="1"/>
    <xsl:param name="cur" select="''"/>
    <xsl:apply-templates>
      <xsl:with-param name="pos" select="$pos"/>
      <xsl:with-param name="cur" select="$cur"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="xhtml:*">
    <xsl:param name="pos" select="1"/>
    <xsl:param name="cur" select="''"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates>
        <xsl:with-param name="pos" select="$pos"/>
        <xsl:with-param name="cur" select="$cur"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*" mode="to-xhtml">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="to-xhtml"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="xhtml:*[@data-insert-html]">
    <xsl:param name="pos" select="1"/>
    <xsl:param name="cur" select="0"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:choose>
        <xsl:when test="$cur">
          <xsl:apply-templates select="$cur//*[local-name() = current()/@data-replace-element]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="($this//*[local-name() = current()/@data-insert-html])[$pos]/node()" mode="to-xhtml"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xhtml:*[@data-set-class-element]">
    <xsl:param name="cur" select="1"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="class">
        <xsl:value-of select="@class"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$cur//*[local-name() = current()/@data-set-class-element]"/>
      </xsl:attribute>
      <xsl:apply-templates>
        <xsl:with-param name="cur" select="$cur"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xhtml:*[@data-select-element]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates>
        <xsl:with-param name="cur"
                        select="$this//*[local-name() = current()/@data-select-element][1]"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xhtml:*[@data-replace-element]">
    <xsl:param name="pos" select="1"/>
    <xsl:param name="cur" select="0"/>
    <xsl:choose>
      <xsl:when test="$cur">
        <xsl:apply-templates mode="children-to-xhtml"
                             select="$cur/descendant-or-self::*[local-name() = current()/@data-replace-element]"/>
      </xsl:when>
      <xsl:when test="@data-replace-element-nth">
        <xsl:apply-templates mode="children-to-xhtml"
                             select="$this/*/x:cont//*[local-name() = current()/@data-replace-element]
                                     [current()/@data-replace-element-nth]"/>
      </xsl:when>
      <xsl:otherwise>
        <!--        Select data element <xsl:value-of select="@data-replace-element"/> nr. <xsl:value-of select="$pos"/>. -->
        <xsl:variable name="hits" select="$this/*/x:cont//*[local-name() = current()/@data-replace-element][$pos]"/>
<!--        <span>nocur(<xsl:value-of select="@data-replace-element"/>, <xsl:value-of select="$pos"/>, <xsl:value-of
           select="$cur"/>) = <xsl:value-of select="count($hits)"/></span>-->
        <xsl:apply-templates mode="children-to-xhtml" select="$hits"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*" mode="repeat-element">
    <xsl:param name="template"/>
    <xsl:variable name="this" select="."/>
    <xsl:variable name="pos" select="position()"/>
    <xsl:for-each select="$template">
<!--      copy template element <xsl:value-of select="name($template)"/> for target element <xsl:value-of
      select="name($this)"/> nr. <xsl:value-of select="$pos"/>.  -->
      <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates>
          <xsl:with-param name="cur" select="$this"/>
        </xsl:apply-templates>
      </xsl:copy>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="xhtml:*[@data-repeat-element]">
    <xsl:apply-templates mode="repeat-element"
                         select="$this/*/x:cont//*[local-name() = current()/@data-repeat-element]">
      <xsl:with-param name="template" select="."/>
    </xsl:apply-templates>
  </xsl:template>

</xsl:stylesheet>
