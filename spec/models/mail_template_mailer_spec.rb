require "spec_helper"
require "mail_template_spec_helper"

describe MailTemplateMailer do
  include ActionDispatch::TestProcess
  include MailTemplateSpecHelper

  reset_domain_tables :mail_templates,:domain_file
  
  before(:each) do
    @user = create_end_user

    @templ = create_mail_tmpl_text
    @templ2 = create_mail_tmpl_html

    fdata = fixture_file_upload("files/rails.png",'image/png')
    @df = DomainFile.create(:filename => fdata) 

    ActionMailer::Base.delivery_method = :test  
    ActionMailer::Base.perform_deliveries = true  
    ActionMailer::Base.deliveries = []  
    
  end
  after(:each) do 
    @df.destroy
  end 
  describe 'Send Email directly to address' do
    it 'should send a message to an email address' do
      @direct_mail = MailTemplateMailer.message_to_address('bugsbunny@mywebiva.net','test subject', {:text => 'test text body',  :html => "<b>test html body", :from => 'admin@mywebiva.net'} ).deliver
      ActionMailer::Base.deliveries.size.should == 1  
      @direct_mail.html_part.to_s.should =~ /<b>test html body/  
    end
    it 'should send mail template to address if available' do
      create_complete_template
      @tmpl_mail = MailTemplateMailer.to_address('bugsbunny@mywebiva.net',3).deliver
      ActionMailer::Base.deliveries.size.should == 1  
      @tmpl_mail.body.should == @body_html      
    end    
    
    it 'should have  email and name if sent to user' do      
      create_complete_template
      @tmpl_mail = MailTemplateMailer.to_user(@user.id,3, {:email => 'your_email'}).deliver
      ActionMailer::Base.deliveries.size.should == 1  
      @tmpl_mail.body.should == @body_html 
    end
    it 'should set the FROM field by the REPLY_TO_EMIL field, if not present' do
      @tmpl_mail = MailTemplateMailer.to_address('bugsbunny@mywebiva.net',1).deliver
      @tmpl_mail.from.should include(Configuration.from_email)
    end
    it 'should raise an error if there is no suitable content type, text or html' do
      Proc.new { MailTemplateMailer.message_to_address('bugsbunny@mywebiva.net','test subject', { 
                                                        :from => 'daffyduck@mywebiva.net'
                                                               } ).deliver }.should raise_error(RuntimeError)
    end
    it 'should determine the mime type of the message' do
      create_complete_template
      @tmpl_mail = MailTemplateMailer.to_user(@user.id,3, {:email => 'your_email'}).deliver
      ActionMailer::Base.deliveries.size.should == 1  
      @tmpl_mail.main_type.should == "text"      
    end

    it 'should send messages to intended user' do
      create_complete_template
      @tmpl_mail = MailTemplateMailer.to_user(@user.id,3, {:email => 'your_email'}).deliver
      ActionMailer::Base.deliveries.size.should == 1  
      @tmpl_mail.to[0].should == "bugsbunny@mywebiva.com"
    end
  end

  def create_email(headers, body)
    headers.collect { |k,v| "#{k}: #{v}" }.join("\n") + "\n" + body
  end

  describe "handle receiving emails" do
    before(:each) do
      @email = Mail::Message.new
      @email.to = 'test@test.dev'
      @email.from = 'admin@test.dev'
      @email.headers 'X-Webiva-Domain' => DomainModel.active_domain_name, 'X-Webiva-Handler' => 'test/handler'
      @email.body = 'Test Body'
    end

    it "should handle incoming mail" do
      DomainModel.should_receive(:activate_domain).exactly(0)
      @email.headers 'X-Webiva-Domain' => DomainModel.active_domain_name
      MailTemplateMailer.receive(@email.to_s)
    end

    it "should handle incoming mail and call handler" do
      mock_handler = mock
      mock_handler.should_receive(:receive)
      handler_info = {:class => mock_handler}
      MailTemplateMailer.should_receive(:get_handler_info).with(:mailing, :receiver, 'test/handler', false).and_return(handler_info)
      MailTemplateMailer.receive(@email.to_s)
    end

    it "should handle incoming bounces and call handler" do
      mock_handler = mock
      mock_handler.should_receive(:receive)
      handler_info = {:class => mock_handler}
      MailTemplateMailer.should_receive(:get_handler_info).with(:mailing, :receiver, 'test/handler', false).and_return(handler_info)

      @orginal = Mail::Message.new
      @orginal.content_type = 'message/rfc822'
      @orginal.body = @email.to_s

      @bounce = Mail::Message.new
      @bounce.content_type = 'multipart/report report-type=delivery-status; boundary=xxxxxx'
      @bounce.mime_version = '1.0'
      @bounce.body = "--xxxxxx\n" + @orginal.to_s

      MailTemplateMailer.receive(@bounce.to_s)
    end
  end
end
