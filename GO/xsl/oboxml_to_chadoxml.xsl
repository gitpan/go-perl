<?xml version = "1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- this transforms oboxml into chadoxml -->
  <!-- chadoxml can be loaded into a chado db using XML::XORT -->
  <!-- does NOT build transitive closure 'cvtermpath' -->
  <!-- use the Pg function fill_cvtermpath for this  -->


  <xsl:output indent="yes" method="xml"/>

  <xsl:key name="terms" match="term" use="id"/>

  <xsl:template match="/">
    <chado>

      <xsl:comment>
        <xsl:text>XORT macros - we can refer to these later</xsl:text>
      </xsl:comment>
      <!-- set macros; ensure the basic stuff is there -->
      <cv op="force" id="relationship">
        <name>relationship</name>
      </cv>
      <cv op="force" id="synonym_type">
        <name>synonym_type</name>
      </cv>
      <cv op="force" id="cvterm_property_type">
        <name>cvterm_property_type</name>
      </cv>

      <db op="force" id="OBO_REL">
        <name>OBO_REL</name>
      </db>
      <db op="force" id="internal">
        <name>internal</name>
      </db>
      <cvterm op="force" id="comment_type">
        <dbxref_id>
          <dbxref>
            <db_id>internal</db_id>
            <accession>cvterm_property_type</accession>
          </dbxref>
        </dbxref_id>
        <cv_id>cvterm_property_type</cv_id>
        <name>comment</name>
      </cvterm>

      <cvterm op="force" id="is_a">
        <dbxref_id>
          <dbxref>
            <db_id>OBO_REL</db_id>
            <accession>is_a</accession>
          </dbxref>
        </dbxref_id>
        <cv_id>relationship</cv_id>
        <name>is_a</name>
        <is_relationshiptype>1</is_relationshiptype>
      </cvterm>

      <!-- terms can appear in different obo file types -->
      <xsl:comment>
        relationship types
      </xsl:comment>
      <xsl:apply-templates select="*/typedef"/>

      <xsl:comment>
        terms
      </xsl:comment>
      <xsl:apply-templates select="*/term"/>

      <xsl:comment>
        is_a relationship types
      </xsl:comment>
      <xsl:apply-templates select="*/term/is_a"/>

      <xsl:comment>
        other relationship types
      </xsl:comment>
      <xsl:apply-templates select="*/term/relationship"/>

      <xsl:comment>
        is_a relationship types between typedefs
      </xsl:comment>
      <xsl:apply-templates select="*/typedef/is_a"/>

    </chado>
  </xsl:template>

  <xsl:template match="term">
    <cvterm>
      <dbxref_id>
        <xsl:apply-templates select="id" mode="dbxref"/>
      </dbxref_id>

      <!-- we must munge the name for obsoletes -->
      <xsl:choose>
        <xsl:when test="is_obsolete">
          <is_obsolete>1</is_obsolete>
          <name>
            <xsl:value-of select="name"/>
            <xsl:text> (obsolete </xsl:text>
            <xsl:value-of select="id"/>
            <xsl:text>)</xsl:text>
          </name>
        </xsl:when>
        <xsl:otherwise>
          <name>
            <xsl:value-of select="name"/>
          </name>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="namespace">
        <cv_id>
          <cv>
            <name>
              <xsl:value-of select="namespace"/>
            </name>
          </cv>
        </cv_id>
      </xsl:if>

      <xsl:apply-templates select="def"/>
      <xsl:apply-templates select="comment"/>
      <xsl:apply-templates select="synonym"/>
      <xsl:apply-templates select="alt_id"/>
      <xsl:apply-templates select="xref_analog"/>
    </cvterm>
  </xsl:template>

  <xsl:template match="typedef">
    <cvterm op="force" id="{id}">
      <dbxref_id>
        <xsl:apply-templates select="id" mode="dbxref"/>
      </dbxref_id>
      <name>
        <!-- note: earlier versions of ontologies had ad-hoc names -->
        <!-- we want to use the ID of the name here -->
        <xsl:choose>
          <xsl:when test="contains(id,':')">
            <!-- we have a 'real' ID, which means the name is real -->
            <xsl:value-of select="name"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- old ontology: ID is actually the name -->
            <xsl:value-of select="id"/>
          </xsl:otherwise>
        </xsl:choose>
      </name>
      <cv_id>relationship</cv_id>
      <xsl:if test="is_obsolete">
        <is_obsolete>1</is_obsolete>
      </xsl:if>
      <is_relationshiptype>1</is_relationshiptype>
      <xsl:if test="def">
        <definition>
          <xsl:value-of select="defstr"/>
        </definition>
      </xsl:if>
      <xsl:apply-templates select="synonym"/>
      <xsl:apply-templates select="alt_id"/>
      <xsl:apply-templates select="xref_analog"/>
    </cvterm>
  </xsl:template>

  <xsl:template match="*" mode="dbxref">
    <xsl:if test="not(.)">
      <xsl:message terminate="yes">
        <xsl:copy select="."/>
        <xsl:text>No ID</xsl:text>
      </xsl:message>
    </xsl:if>
    <dbxref>
      <!-- IDs that are not prefixed with a dbspace should
           have a default dbspace prefixed. however, obo format
           files have no concept of a default dbspace. it turns
           out that the only IDs without a db prefix are relationship
           types, so we can place these in OBO_REL by default
           -->
      <xsl:choose>
        <xsl:when test="contains(.,':')">
          <db_id>
            <db>
              <name>
                <xsl:value-of select="substring-before(.,':')"/>    
              </name>
            </db>
          </db_id>
          <accession>
            <xsl:value-of select="substring-after(.,':')"/>    
          </accession>
        </xsl:when>
        <xsl:otherwise>
          <db_id>OBO_REL</db_id>
          <accession>
            <xsl:value-of select="."/>
          </accession>
        </xsl:otherwise>
      </xsl:choose>
    </dbxref>
  </xsl:template>

  <xsl:template match="is_a">
    <cvterm_relationship>
      <type_id>is_a</type_id>
      <subject_id>
        <cvterm op="lookup">
          <dbxref_id>
            <xsl:apply-templates select="../id" mode="dbxref"/>
          </dbxref_id>
        </cvterm>
      </subject_id>
      <object_id>
        <cvterm op="lookup">
          <dbxref_id>
            <xsl:apply-templates select="." mode="dbxref"/>
          </dbxref_id>
        </cvterm>
      </object_id>
    </cvterm_relationship>
  </xsl:template>

  <xsl:template match="relationship">
    <cvterm_relationship>
      <type_id><xsl:value-of select="type"/></type_id>
      <subject_id>
        <cvterm op="lookup">
          <dbxref_id>
            <xsl:apply-templates select="../id" mode="dbxref"/>
          </dbxref_id>
        </cvterm>
      </subject_id>
      <object_id>
        <cvterm op="lookup">
          <dbxref_id>
            <xsl:apply-templates select="to" mode="dbxref"/>
          </dbxref_id>
        </cvterm>
      </object_id>
    </cvterm_relationship>
  </xsl:template>

  <xsl:template match="synonym">
    <cvtermsynonym>
      <synonym>
        <xsl:value-of select="synonym_text"/>
      </synonym>
      <xsl:if test="@scope">
        <type_id>
          <cvterm>
            <dbxref_id>
              <dbxref>
                <db_id>internal</db_id>
                <accession>
                  <xsl:value-of select="@scope"/>
                </accession>
              </dbxref>
            </dbxref_id>
            <cv_id>synonym_type</cv_id>
            <name>
              <xsl:value-of select="@scope"/>
            </name>
          </cvterm>
        </type_id>
      </xsl:if>
    </cvtermsynonym>
  </xsl:template>
    
  <xsl:template match="comment">
    <cvtermprop>
      <type_id>comment_type</type_id>
      <value>
        <xsl:value-of select="."/>
      </value>
      <rank>0</rank>
    </cvtermprop>
  </xsl:template>
    
  <xsl:template match="xref_analog">
    <cvterm_dbxref>
      <dbxref_id>
        <dbxref>
          <db_id>
            <db>
              <name>
                <xsl:value-of select="dbname"/>
              </name>
            </db>
          </db_id>
          <accession>
            <xsl:value-of select="acc"/>
          </accession>
        </dbxref>
      </dbxref_id>
    </cvterm_dbxref>
  </xsl:template>
    
  <xsl:template match="dbxref" mode="is_for_definition">
    <cvterm_dbxref>
      <dbxref_id>
        <dbxref>
          <db_id>
            <db>
              <name>
                <xsl:value-of select="dbname"/>
              </name>
            </db>
          </db_id>
          <accession>
            <xsl:value-of select="acc"/>
          </accession>
        </dbxref>
      </dbxref_id>
      <is_for_definition>1</is_for_definition>
    </cvterm_dbxref>
  </xsl:template>
    
  <xsl:template match="alt_id">
    <cvterm_dbxref>
      <dbxref_id>
        <xsl:apply-templates select="." mode="dbxref"/>
      </dbxref_id>
    </cvterm_dbxref>
  </xsl:template>
  
  <xsl:template match="def">
    <definition>
      <xsl:value-of select="defstr"/>
    </definition>
	<xsl:if test="string-length(dbxref/acc) > 0 and string-length(dbxref/dbname) > 0">
        <xsl:apply-templates select="dbxref" mode="is_for_definition"/>
	</xsl:if>
  </xsl:template>

  <xsl:template match="prod">
    <feature>
      <dbxref>
        <db>
          <name>
            <xsl:value-of select="../proddb"/>
          </name>
        </db>
        <accession>
          <xsl:value-of select="prodacc"/>
        </accession>
      </dbxref>
      <name>
        <xsl:value-of select="prodsymbol"/>
      </name>
      <uniquename>
        <xsl:value-of select="prodsymbol"/>
      </uniquename>
      <type>
        <cvterm>
          <name>
            <xsl:value-of select="prodtype"/>
          </name>
          <cv>
            <name>
              sequence
            </name>
          </cv>
        </cvterm>
      </type>
      <organism>
        <dbxref>
          <db>
            <name>
              ncbi_taxononmy
            </name>
          </db>
          <accession>
            <xsl:value-of select="prodtaxa"/>
          </accession>
        </dbxref>
      </organism>
      <xsl:apply-templates select="assoc"/>
    </feature>
  </xsl:template>

  <xsl:template match="assoc">
    <feature_cvterm>
      <cvterm>
        <xsl:apply-templates select="termacc" mode="dbxref"/>
      </cvterm>
      <xsl:apply-templates select="evidence"/>
    </feature_cvterm>
  </xsl:template>

  <xsl:template match="evidence">
    <feature_cvtermprop>
    </feature_cvtermprop>
  </xsl:template>

  <xsl:template match="text()|@*">
  </xsl:template>


</xsl:stylesheet>



