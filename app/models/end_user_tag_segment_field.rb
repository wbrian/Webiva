
class EndUserTagSegmentField < UserSegment::FieldHandler

  def self.user_segment_fields_handler_info
    {
      :name => 'User Tag Fields',
      :domain_model_class => EndUserTag
    }
  end

  class EndUserTagType < UserSegment::FieldType
    register_operation :is, [['Tag', :model, {:class => EndUserTagSegmentField::EndUserTagType}]]

    def self.select_options
      Tag.find(:all, :select => 'name').collect(&:name).sort.collect { |name| [name, name] }
    end

    def self.is(cls, group_field, field, name)
      tg = Tag.find_by_name name
      id = tg ? tg.id : 0
      cls.scoped(:conditions => ["#{field} = ?", id])
    end
  end

  register_field :tag, EndUserTagSegmentField::EndUserTagType, :field => :tag_id, :name => 'Tag', :sortable => true, :display_field => :tag

  def self.sort_scope(order_by, direction)
    EndUserTag.scoped :joins => :tag, :order => "tags.name #{direction}"
  end

  def self.get_handler_data(ids, fields)
    EndUserTag.find(:all, :include => 'tag', :conditions => {:end_user_id => ids}).group_by(&:end_user_id)
  end

  def self.field_output(user, handler_data, field)
    UserSegment::FieldType.field_output(user, handler_data, field)
  end
end
