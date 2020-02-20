module UI
class Picker < Control
include Eventable

attr_reader :data_source

def initialize
@data_source=[]
super
end

def data_source=(data)
@data_source=data
reload
end

def pickerView(picker_view, titleForRow: row, forComponent: component)
@data_source[row]
end

def numberOfComponentsInPickerView(picker_view)
      1
    end

def pickerView(picker_view, numberOfRowsInComponent: sec)
return @data_source.size
end

def pickerView(picker_view, didSelectRow: row, inComponent: component)
trigger(:select, @data_source[row], row, component)
end

def reload
proxy.reloadAllComponents
end

def proxy
@proxy ||= begin
ui_pickerview = UIPickerView.alloc.init
ui_pickerview.dataSource=self
ui_pickerview.delegate=self
ui_pickerview
end
end
end
end
