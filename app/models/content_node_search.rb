
class ContentNodeSearch < HashModel
  attributes :terms => nil, :per_page => 10, :content_type_id => nil, :page => 0, :max_per_page => 50, :protected_results => false

  integer_options :per_page, :page, :content_type_id, :max_per_page
  boolean_options :protected_results

  def validate
    errors.add(:per_page) if self.per_page > self.max_per_page || self.per_page < 1
    errors.add(:content_type_id) if ! self.valid_content_type?
  end

  def search?
    ! self.terms.blank?
  end

  def valid_content_type?
    ! self.content_types_options.rassoc(self.content_type_id).nil?
  end

  # if they are logged in they can see protected results
  def set_protected_results(myself)
    self.protected_results = myself.id ? true : false
  end

  def content_types_options
    return @content_types_options if @content_types_options
    opts = { :conditions => {:search_results => 1} }
    opts[:conditions][:protected_results] = 0 if self.protected_results.blank?
    @content_types_options = ContentType.select_options_with_nil 'Everything', opts
  end

  def language
    return @language if @language
    @language = Configuration.languages[0]
  end

  def language=(language)
    @language = language
  end

  def frontend_search
    return [@results, @total_results] if @results

    conditions = {:search_result => 1}
    conditions[:content_type_id] = self.content_type_id if self.content_type_id
    conditions[:protected_result] = 0 if self.protected_results.blank?

    @results, @total_results = ContentNode.search(self.language, self.terms,
						  :conditions => conditions,
						  :limit => self.per_page,
						  :offset => self.page * self.per_page
						  )
    @results.map! do |node|
      content_description =  node.content_description(language)

      { 
	:title => node.title,
	:subtitle => content_description || node.content_type.content_name,
	:url => node.link,
	:preview => node.preview,
	:excerpt => node.excerpt,
	:node => node
      }
    end
    
    [@results, @total_results]
  end

  def backend_search
    return [@results, @total_results] if @results

    conditions = {:search_result => 1}
    conditions[:content_type_id] = self.content_type_id if self.content_type_id

    @results, @total_results = ContentNode.search(self.language, self.terms,
						  :conditions => conditions,
						  :limit => self.per_page,
						  :offset => self.page * self.per_page
						  )
    @results.map! do |node|
      content_description =  node.content_description(language)

      { 
	:title => node.title,
	:subtitle => content_description || node.content_type.content_name,
	:url => node.link,
	:link => node.link,
	:preview => node.preview,
	:excerpt => node.excerpt,
	:node => node
      }
    end
    
    [@results, @total_results]
  end
end
