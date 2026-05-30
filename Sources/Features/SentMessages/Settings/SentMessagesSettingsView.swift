import SwiftUI

struct SentMessagesSettingsView: View {
    let wrapper: SentMessagesSettingsWrapper

    @State private var assistantName = ""
    @State private var messagePrefix = ""
    @State private var messagePostfix = ""
    @State private var messageHeader = ""
    @State private var messageFooter = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Assistant Name", text: assistantNameBinding)
            TextField("Message Header", text: messageHeaderBinding)
            TextField("Message Prefix", text: messagePrefixBinding)
            TextField("Message Postfix", text: messagePostfixBinding)
            TextField("Message Footer", text: messageFooterBinding)

            Text("Empty values mean no extra formatting is applied.")
                .foregroundStyle(.secondary)
        }
        .task {
            assistantName = wrapper.assistantName
            messagePrefix = wrapper.messagePrefix
            messagePostfix = wrapper.messagePostfix
            messageHeader = wrapper.messageHeader
            messageFooter = wrapper.messageFooter
        }
    }

    private var assistantNameBinding: Binding<String> {
        Binding {
            assistantName
        } set: { value in
            assistantName = value
            wrapper.assistantName = value
        }
    }

    private var messagePrefixBinding: Binding<String> {
        Binding {
            messagePrefix
        } set: { value in
            messagePrefix = value
            wrapper.messagePrefix = value
        }
    }

    private var messagePostfixBinding: Binding<String> {
        Binding {
            messagePostfix
        } set: { value in
            messagePostfix = value
            wrapper.messagePostfix = value
        }
    }

    private var messageHeaderBinding: Binding<String> {
        Binding {
            messageHeader
        } set: { value in
            messageHeader = value
            wrapper.messageHeader = value
        }
    }

    private var messageFooterBinding: Binding<String> {
        Binding {
            messageFooter
        } set: { value in
            messageFooter = value
            wrapper.messageFooter = value
        }
    }
}
